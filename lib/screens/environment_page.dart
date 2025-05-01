import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'sensor_data_model.dart';

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

  Timer? timer;
  final random = Random();

  bool get isAddressFilled =>
      addressLine1.isNotEmpty &&
      city.isNotEmpty &&
      postcode.isNotEmpty &&
      country.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (isAddressFilled) _startSimulation();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    timer?.cancel();
    SensorDataModel().startAveraging();
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        light = 100 + random.nextDouble() * 900;
        temperature = 15 + random.nextDouble() * 15;
        humidity = 30 + random.nextDouble() * 70;
        pressure = 980 + random.nextDouble() * 40;

        _updateHistory(lightHistory, light);
        _updateHistory(temperatureHistory, temperature);
        _updateHistory(humidityHistory, humidity);
        _updateHistory(pressureHistory, pressure);

        SensorDataModel().updateSensors(
          light: light,
          temperature: temperature,
          humidity: humidity,
          pressure: pressure,
        );
      });
    });
  }

  void _updateHistory(List<double> history, double value) {
    history.add(value);
    if (history.length > 60) history.removeAt(0);
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
            Row(
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
                        builder: (context) => EditAddressPage(
                          addressLine1: addressLine1,
                          addressLine2: addressLine2,
                          city: city,
                          postcode: postcode,
                          country: country,
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        addressLine1 = result['addressLine1'];
                        addressLine2 = result['addressLine2'];
                        city = result['city'];
                        postcode = result['postcode'];
                        country = result['country'];
                      });
                      if (isAddressFilled) {
                        _startSimulation();
                      } else {
                        timer?.cancel();
                      }
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildSensorCard(Icons.wb_sunny, 'Ambient Light', light, 'lux', Colors.yellow.shade600),
            SizedBox(height: 16),
            _buildSensorCard(Icons.thermostat, 'Temperature', temperature, '°C', Colors.redAccent),
            SizedBox(height: 16),
            _buildSensorCard(Icons.water_drop, 'Humidity', humidity, '%', Colors.blueAccent),
            SizedBox(height: 16),
            _buildSensorCard(Icons.speed, 'Air Pressure', pressure, 'hPa', Colors.deepPurpleAccent),
            SizedBox(height: 30),
            Container(
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
                      'Sensor History                                                                 (last hour / one reading per miniute)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendDot(color: Colors.yellow.shade700, label: 'Light (lux)'),
                _buildLegendDot(color: Colors.redAccent, label: 'Temperature (°C)'),
                _buildLegendDot(color: Colors.blueAccent, label: 'Humidity (%)'),
                _buildLegendDot(color: Colors.deepPurpleAccent, label: 'Pressure (hPa)'),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: false),
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
            ),
            SizedBox(height: 20),
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

  Widget _buildLegendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}


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

  @override
  void initState() {
    super.initState();
    addressLine1 = widget.addressLine1;
    addressLine2 = widget.addressLine2;
    city = widget.city;
    postcode = widget.postcode;
    country = widget.country;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Home Address'),
        backgroundColor: Colors.orangeAccent,
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
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => addressLine1 = value ?? '',
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: addressLine2,
                decoration: InputDecoration(labelText: 'Street / Block (optional)'),
                onSaved: (value) => addressLine2 = value ?? '',
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: city,
                decoration: InputDecoration(labelText: 'City *'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => city = value ?? '',
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: postcode,
                decoration: InputDecoration(labelText: 'Postcode *'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => postcode = value ?? '',
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: country,
                decoration: InputDecoration(labelText: 'Country *'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => country = value ?? '',
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Navigator.pop(context, {
                      'addressLine1': addressLine1,
                      'addressLine2': addressLine2,
                      'city': city,
                      'postcode': postcode,
                      'country': country,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                child: Text('Save'),
              )
            ],
          ),
        ),
      ),
    );
  }
}