import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

import 'top_up_page.dart';
import 'sensor_data_model.dart';

class HomePage extends StatefulWidget {
  final List<Map<String, dynamic>> devices;
  final VoidCallback onViewDevices;

  HomePage({Key? key, required this.devices, required this.onViewDevices}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double accountBalance = 0.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String userName = 'User';
  String userLocation = 'Locating...';
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  LatLng? _homeAddressLatLng;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<DocumentSnapshot>? _userStream;
  bool _mapExpanded = false;

  String weatherDescription = '';
  String cityName = '';
  double temperatureCelsius = 0.0;
  double humidity = 0.0;
  double windSpeed = 0.0;
  List<Map<String, dynamic>> hourlyForecast = [];

  @override
  void initState() {
    super.initState();
    _listenToUserData();
    _determinePositionAndAddress();
    _startLocationUpdates();
    _loadHomeAddressLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _userStream?.cancel();
    super.dispose();
  }

  void _listenToUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            userName = data?['name'] ?? 'User';
            accountBalance = (data?['balance'] ?? 0).toDouble();
          });
        }
      });
    }
  }

  void _loadHomeAddressLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        final address = data?['address'];
        if (address != null && address.toString().isNotEmpty) {
          try {
            final locations = await locationFromAddress(address);
            if (locations.isNotEmpty) {
              setState(() {
                _homeAddressLatLng = LatLng(locations.first.latitude, locations.first.longitude);
              });
            }
          } catch (e) {
            print("Failed to locate home address: $e");
          }
        }
      }
    }
  }

  void _determinePositionAndAddress() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => userLocation = 'Location services disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => userLocation = 'Location permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => userLocation = 'Location permission permanently denied');
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      setState(() {
        userLocation = '${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
        _currentLatLng = LatLng(position.latitude, position.longitude);
      });
      _fetchWeather(position.latitude, position.longitude);
    }
  }

  void _startLocationUpdates() {
    const locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      final updatedLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLatLng = updatedLatLng;
      });
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(updatedLatLng));
      }
    });
  }

void _fetchWeather(double lat, double lon) async {
  final apiKey = 'a3ff1efc32898aafb3690fe87e70d2fd';

  // get current weather data
  final currentUrl = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric');

  // get 3 hours each forecast weather data
  final forecastUrl = Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric');

  try {
    final currentResponse = await http.get(currentUrl);
    final forecastResponse = await http.get(forecastUrl);

    if (currentResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
      final currentData = json.decode(currentResponse.body);
      final forecastData = json.decode(forecastResponse.body);

      setState(() {
        cityName = currentData['name'] ?? 'Unknown';
        weatherDescription = currentData['weather'][0]['description'];
        temperatureCelsius = currentData['main']['temp'].toDouble();
        humidity = currentData['main']['humidity'].toDouble();
        windSpeed = currentData['wind']['speed'].toDouble();

        final forecastList = forecastData['list'] as List<dynamic>;

        //(use openweather One Call API）
        hourlyForecast = forecastList.take(6).map<Map<String, dynamic>>((entry) {
          final dateTime = DateTime.parse(entry['dt_txt']);
          return {
            'time': '${dateTime.hour.toString().padLeft(2, '0')}:00',
            'temp': entry['main']['temp'],
            'desc': entry['weather'][0]['description'],
          };
        }).toList();
      });
    } else {
      print('Weather fetch error: ${currentResponse.body} / ${forecastResponse.body}');
    }
  } catch (e) {
    print('Exception during weather fetch: $e');
  }
}


  Widget _buildWeatherCard() {
    IconData weatherIcon;
    if (weatherDescription.toLowerCase().contains('cloud')) {
      weatherIcon = Icons.cloud;
    } else if (weatherDescription.toLowerCase().contains('rain')) {
      weatherIcon = Icons.grain;
    } else if (weatherDescription.toLowerCase().contains('sun') || weatherDescription.toLowerCase().contains('clear')) {
      weatherIcon = Icons.wb_sunny;
    } else if (weatherDescription.toLowerCase().contains('snow')) {
      weatherIcon = Icons.ac_unit;
    } else {
      weatherIcon = Icons.thermostat;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(weatherIcon, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text('Current Weather', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
            ]),
            SizedBox(height: 10),
            Text(cityName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('$weatherDescription', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🌡️ ${temperatureCelsius.toStringAsFixed(1)} °C', style: TextStyle(fontSize: 16)),
                Text('💧 ${humidity.toStringAsFixed(0)}%', style: TextStyle(fontSize: 16)),
                Text('🌬️ ${windSpeed.toStringAsFixed(1)} m/s', style: TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildForecastCard() {
  double minTemp = hourlyForecast.map((e) => e['temp'] as double).reduce((a, b) => a < b ? a : b);
  double maxTemp = hourlyForecast.map((e) => e['temp'] as double).reduce((a, b) => a > b ? a : b);
  double yMin = (minTemp - 2).floorToDouble();
  double yMax = (maxTemp + 2).ceilToDouble();

  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.schedule, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('6-Hour Forecast', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
          ]),
          SizedBox(height: 16),

          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: yMin,
                maxY: yMax,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        int index = value.toInt();
                        if (index >= 0 && index < hourlyForecast.length) {
                          return Text(hourlyForecast[index]['time'], style: TextStyle(fontSize: 12));
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 40,
                      getTitlesWidget: (value, _) =>
                          Text('${value.toInt()}°', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(hourlyForecast.length, (i) {
                      return FlSpot(i.toDouble(), hourlyForecast[i]['temp']);
                    }),
                    isCurved: true,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    color: Colors.orangeAccent,
                  )
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // list（time + icon + description + temperature)
          Column(
            children: hourlyForecast.map((entry) {
              IconData icon = _getWeatherIcon(entry['desc']);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry['time'], style: TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        Icon(icon, color: Colors.blueGrey),
                        SizedBox(width: 6),
                        Text(entry['desc'], style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    Text('${entry['temp'].toStringAsFixed(1)} °C', style: TextStyle(fontSize: 16)),
                  ],
                ),
              );
            }).toList(),
          )
        ],
      ),
    ),
  );
}


IconData _getWeatherIcon(String description) {
  final desc = description.toLowerCase();
  if (desc.contains('cloud')) return Icons.cloud;
  if (desc.contains('rain') || desc.contains('shower')) return Icons.grain;
  if (desc.contains('clear') || desc.contains('sun')) return Icons.wb_sunny;
  if (desc.contains('snow')) return Icons.ac_unit;
  if (desc.contains('storm') || desc.contains('thunder')) return Icons.flash_on;
  return Icons.thermostat;
}


  Widget _buildWeatherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeatherCard(),
        SizedBox(height: 16),
        _buildForecastCard(),
      ],
    );
  }

  void _showNavigateDialog() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Credit',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
        content: Text('Do you want to go to the Top Up page?',
            style: TextStyle(fontSize: 18, color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('No')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final credit = await Navigator.push(context, MaterialPageRoute(builder: (_) => TopUpPage()));
              if (credit != null && credit is double) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                    final snapshot = await transaction.get(userDoc);
                    final currentBalance = (snapshot.data()?['balance'] ?? 0).toDouble();
                    transaction.update(userDoc, {'balance': currentBalance + credit});
                  });
                }
              }
            },
            child: Text('Yes'),
          )
        ],
      ),
    );
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  bool get isAddressFilled {
    final model = Provider.of<SensorDataModel>(context, listen: false);
    return model.lightHistory.isNotEmpty || model.temperatureHistory.isNotEmpty;
  }

 @override
Widget build(BuildContext context) {
  final totalDevices = widget.devices.length;
  final onlineDevices = widget.devices.where((d) => d['isOnline'] == true).length;

  return Scaffold(
    key: _scaffoldKey,
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.orangeAccent,
      title: Text('Welcome back, $userName!'),
      leading: IconButton(icon: Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
    ),
    drawer: Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.orangeAccent),
            child: Text('WiseWatts Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(leading: Icon(Icons.person), title: Text('Profile')),
          ListTile(leading: Icon(Icons.settings), title: Text('Settings')),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    ),
    body: Consumer<SensorDataModel>(
      builder: (context, model, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationSection(),
              _buildMapSection(),
              _buildBalanceCard(),
              SizedBox(height: 24),
              _buildWeatherSection(),
              SizedBox(height: 24),
              _buildSensorCard(model),
              SizedBox(height: 24),
              _buildDevicesCard(totalDevices, onlineDevices),
            ],
          ),
        );
      },
    ),
  );
}


  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Location:', style: TextStyle(fontSize: 12, color: Colors.grey)),
        SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on, color: Colors.orangeAccent),
            SizedBox(width: 6),
            Expanded(child: Text(userLocation, style: TextStyle(fontSize: 16, color: Colors.grey[800]))),
          ],
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _mapExpanded = !_mapExpanded),
          child: Row(
            children: [
              Icon(_mapExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.blue),
              SizedBox(width: 4),
              Text(_mapExpanded ? 'Hide Map' : 'Show Map',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _mapExpanded && _currentLatLng != null ? 250 : 0,
      margin: EdgeInsets.only(top: 12, bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _currentLatLng != null
            ? GoogleMap(
                initialCameraPosition: CameraPosition(target: _currentLatLng!, zoom: 16),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: {
                  Marker(
                    markerId: MarkerId('current'),
                    position: _currentLatLng!,
                    infoWindow: InfoWindow(title: 'You are here'),
                  ),
                  if (_homeAddressLatLng != null)
                    Marker(
                      markerId: MarkerId('home'),
                      position: _homeAddressLatLng!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      infoWindow: InfoWindow(title: 'Home Address'),
                    )
                },
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              )
            : SizedBox.shrink(),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Account Balance:', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
            SizedBox(height: 10),
            Center(
                child: Text('£${accountBalance.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold))),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _showNavigateDialog,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add credit',
                      style:
                          TextStyle(fontSize: 18, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                  Icon(Icons.chevron_right, color: Colors.blue.shade800),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(SensorDataModel model) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Avg. Home Sensor Readings           (Last Hour)',
                style: TextStyle(fontSize: 18, color: Colors.grey[700])),
            SizedBox(height: 10),
            _buildSensorRow(Icons.wb_sunny, 'Light:',
                isAddressFilled ? model.lightAvg : null, 'lux'),
            _buildSensorRow(Icons.thermostat, '         Temperature:',
                isAddressFilled ? model.tempAvg : null, '°C'),
            _buildSensorRow(Icons.water_drop, '  Humidity:',
                isAddressFilled ? model.humidityAvg : null, '%'),
            _buildSensorRow(Icons.speed, '          Pressure:',
                isAddressFilled ? model.pressureAvg : null, 'hPa'),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesCard(int totalDevices, int onlineDevices) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Devices:', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: $totalDevices', style: TextStyle(fontSize: 16)),
                Text('Online: $onlineDevices', style: TextStyle(fontSize: 16, color: Colors.green)),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.onViewDevices,
              child: Text('View Devices'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSensorRow(IconData icon, String label, double? value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.orangeAccent),
          Text(label, style: TextStyle(fontSize: 16)),
          Text(value == null ? '-- $unit' : '${value.toStringAsFixed(1)} $unit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
