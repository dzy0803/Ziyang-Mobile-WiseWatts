import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sensor_data_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:environment_sensors/environment_sensors.dart';
import 'package:firebase_database/firebase_database.dart';




class EditAddressPage extends StatefulWidget {
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String postcode;
  final String country;

  EditAddressPage({
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.postcode,
    required this.country,
  });

  @override
  _EditAddressPageState createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  late String addressLine1;
  late String addressLine2;
  late String city;
  late String postcode;
  late String country;

  LatLng? location;
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    addressLine1 = widget.addressLine1;
    addressLine2 = widget.addressLine2;
    city = widget.city;
    postcode = widget.postcode;
    country = widget.country;
    _updateMapLocation(); // Initial map location
  }

  // Convert address string to geographic coordinates
  Future<void> _updateMapLocation() async {
    final fullAddress =
        '$addressLine1 ${addressLine2.isNotEmpty ? addressLine2 + ',' : ''} $city, $postcode, $country';
    try {
      List<Location> locations = await locationFromAddress(fullAddress);
      if (locations.isNotEmpty) {
        setState(() {
          location =
              LatLng(locations.first.latitude, locations.first.longitude);
        });
        mapController?.animateCamera(CameraUpdate.newLatLng(location!));
      }
    } catch (e) {
      print('Geocoding failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not locate this address.')),
      );
    }
  }

  // Save form data, update map and sync to Firebase
  void _handleSaveAndUpdateMap() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      await _updateMapLocation();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final fullAddress =
            '$addressLine1${addressLine2.isNotEmpty ? ', $addressLine2' : ''}, $city, $postcode, $country';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'addressLine1': addressLine1,
          'addressLine2': addressLine2,
          'city': city,
          'postcode': postcode,
          'country': country,
          'address': fullAddress, // Updated readable address
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Address updated and synced to cloud.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User not logged in.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Return updated address to EnvironmentPage
  void _returnWithData() {
    Navigator.pop(context, {
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'postcode': postcode,
      'country': country,
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapHeight = MediaQuery.of(context).size.height * 0.3;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Home Address'),
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            tooltip: 'Return with Address',
            onPressed: _returnWithData,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: addressLine1,
                decoration: InputDecoration(labelText: 'Address Line 1 *'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => addressLine1 = value ?? '',
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: addressLine2,
                decoration:
                    InputDecoration(labelText: 'Street / Block (optional)'),
                onSaved: (value) => addressLine2 = value ?? '',
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: city,
                decoration: InputDecoration(labelText: 'City *'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => city = value ?? '',
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: postcode,
                decoration: InputDecoration(labelText: 'Postcode *'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => postcode = value ?? '',
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: country,
                decoration: InputDecoration(labelText: 'Country *'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => country = value ?? '',
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleSaveAndUpdateMap,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent),
                icon: Icon(Icons.save),
                label: Text('Save and Update Map'),
              ),
              SizedBox(height: 30),
              Text('Map Location Preview',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Container(
                height: mapHeight,
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.grey)),
                child: location == null
                    ? Center(child: Text('Address not located'))
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: location!,
                          zoom: 16,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId('home'),
                            position: location!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueAzure), // 💙 Blue marker
                            infoWindow: InfoWindow(title: 'Home Address'),
                          )
                        },
                        onMapCreated: (controller) =>
                            mapController = controller,
                        zoomControlsEnabled: false,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class EnvironmentPage extends StatefulWidget {
  @override
  _EnvironmentPageState createState() => _EnvironmentPageState();
}

class _EnvironmentPageState extends State<EnvironmentPage> {
  String addressLine1 = '';
  String addressLine2 = '';
  String city = '';
  String postcode = '';
  String country = '';

  double light = 0;
  double temperature = 0;
  double humidity = 0;
  double pressure = 0;

  final List<double> lightHistory = [];
  final List<double> temperatureHistory = [];
  final List<double> humidityHistory = [];
  final List<double> pressureHistory = [];
  final List<DateTime> timeHistory = [];

  Timer? timer;
  final random = Random();

  final EnvironmentSensors _environmentSensors = EnvironmentSensors();
  StreamSubscription<double>? _lightSubscription;

  final DatabaseReference dhtSensorRef =
      FirebaseDatabase.instance.ref('sensors/dht11_sensor');

  bool get isAddressFilled =>
      addressLine1.isNotEmpty &&
      city.isNotEmpty &&
      postcode.isNotEmpty &&
      country.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadAddressFromFirebase();
  }

  @override
  void dispose() {
    timer?.cancel();
    _lightSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAddressFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        setState(() {
          addressLine1 = data['addressLine1'] ?? '';
          addressLine2 = data['addressLine2'] ?? '';
          city = data['city'] ?? '';
          postcode = data['postcode'] ?? '';
          country = data['country'] ?? '';
        });

        if (isAddressFilled) {
          _startSensorListeners();
        }
      }
    }
  }

  void _startSensorListeners() {
    timer?.cancel();
    _lightSubscription?.cancel();

    SensorDataModel().startAveraging();

    _lightSubscription = _environmentSensors.light.listen((lux) {
      setState(() {
        light = lux;
        _updateHistory(lightHistory, light);
      });
    });

    timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        pressure = 980 + random.nextDouble() * 40;
        _updateHistory(pressureHistory, pressure);
      });
    });
  }

  void _updateHistory(List<double> history, double value) {
    history.add(value);
    timeHistory.add(DateTime.now());

    if (history.length > 60) {
      history.removeAt(0);
      timeHistory.removeAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    String fullAddress = isAddressFilled
        ? '$addressLine1${addressLine2.isNotEmpty ? ', $addressLine2' : ''}, $city, $postcode, $country'
        : 'No address set';

    return Scaffold(
      appBar: AppBar(
        title: Text('Environment Monitor'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddressCard(fullAddress),
            SizedBox(height: 24),
            _buildSensorCard(Icons.wb_sunny, 'Ambient Light', light, 'lux', Colors.yellow.shade600),
            SizedBox(height: 16),
            _buildTemperatureHumidityFromRealtimeDB(),
            SizedBox(height: 16),
            _buildSensorCard(Icons.speed, 'Air Pressure', pressure, 'hPa', Colors.deepPurpleAccent),
            SizedBox(height: 30),
            _buildChartLegend(),
            SizedBox(height: 12),
            _buildChart(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureHumidityFromRealtimeDB() {
    return StreamBuilder<DatabaseEvent>(
      stream: dhtSensorRef.onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return Column(
            children: [
              _buildSensorCard(Icons.thermostat, 'Temperature', 0, '°C', Colors.redAccent),
              SizedBox(height: 16),
              _buildSensorCard(Icons.water_drop, 'Humidity', 0, '%', Colors.blueAccent),
            ],
          );
        }

        final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final temp = (data['temperature'] ?? 0).toDouble();
        final hum = (data['humidity'] ?? 0).toDouble();

        _updateHistory(temperatureHistory, temp);
        _updateHistory(humidityHistory, hum);

        SensorDataModel().updateSensors(
          light: light,
          temperature: temp,
          humidity: hum,
          pressure: pressure,
        );

        return Column(
          children: [
            _buildSensorCard(Icons.thermostat, 'Temperature', temp, '°C', Colors.redAccent),
            SizedBox(height: 16),
            _buildSensorCard(Icons.water_drop, 'Humidity', hum, '%', Colors.blueAccent),
          ],
        );
      },
    );
  }

  Widget _buildAddressCard(String fullAddress) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.home, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Home Address: $fullAddress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.orangeAccent),
              onPressed: () async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EditAddressPage(
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        postcode: postcode,
        country: country,
      ),
    ),
  );

  if (result != null && result is Map) {
    setState(() {
      addressLine1 = result['addressLine1'];
      addressLine2 = result['addressLine2'];
      city = result['city'];
      postcode = result['postcode'];
      country = result['country'];
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'city': city,
        'postcode': postcode,
        'country': country,
      });
    }

    if (isAddressFilled) {
      _startSensorListeners();
    } else {
      timer?.cancel();
    }
  }
}

            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(IconData icon, String label, double value, String unit, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                SizedBox(height: 6),
                Text(
                  isAddressFilled ? '${value.toStringAsFixed(1)} $unit' : '-- $unit',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.show_chart, color: Colors.orangeAccent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sensor Reading Flow',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 10,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= timeHistory.length) return Text('');
                  final t = timeHistory[index];
                  final label = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 6,
                    child: Text(label, style: TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: lightHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              color: Colors.yellow.shade700,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
            LineChartBarData(
              spots: temperatureHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
            LineChartBarData(
              spots: humidityHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
            LineChartBarData(
              spots: pressureHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              color: Colors.deepPurpleAccent,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}