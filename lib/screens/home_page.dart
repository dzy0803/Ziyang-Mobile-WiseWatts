import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  bool _mapExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _determinePositionAndAddress();
    _startLocationUpdates();
    _loadHomeAddressLocation(); // Load home address marker
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          userName = data?['name'] ?? 'User';
        });
      }
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
        userLocation =
            '${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
        _currentLatLng = LatLng(position.latitude, position.longitude);
      });
    }
  }

  void _startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

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
                setState(() {
                  accountBalance += credit;
                });
              }
            },
            child: Text('Yes'),
          )
        ],
      ),
    );
  }

  void _logout() {
    setState(() {
      accountBalance = 0.0;
    });
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
                Text('Your Location:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: Colors.orangeAccent),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(userLocation, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                    ),
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
                AnimatedContainer(
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
                ),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Account Balance:',
                            style: TextStyle(fontSize: 18, color: Colors.grey[700])),
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
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.bold)),
                              Icon(Icons.chevron_right, color: Colors.blue.shade800),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Avg. Sensor Readings (Last Hour)',
                            style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                        SizedBox(height: 10),
                        _buildSensorRow(Icons.wb_sunny, 'Light',
                            isAddressFilled ? model.lightAvg : null, 'lux'),
                        _buildSensorRow(Icons.thermostat, 'Temperature',
                            isAddressFilled ? model.tempAvg : null, '°C'),
                        _buildSensorRow(Icons.water_drop, 'Humidity',
                            isAddressFilled ? model.humidityAvg : null, '%'),
                        _buildSensorRow(Icons.speed, 'Pressure',
                            isAddressFilled ? model.pressureAvg : null, 'hPa'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Card(
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
                            Text('Online: $onlineDevices',
                                style: TextStyle(fontSize: 16, color: Colors.green)),
                          ],
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: widget.onViewDevices,
                          child: Text('View Devices'),
                          style:
                              ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
