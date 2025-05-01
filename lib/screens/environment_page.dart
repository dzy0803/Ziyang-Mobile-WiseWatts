import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    String fullAddress = (addressLine1.isEmpty || city.isEmpty || postcode.isEmpty || country.isEmpty)
        ? 'No address set'
        : '$addressLine1${addressLine2.isNotEmpty ? ', $addressLine2' : ''}, $city, $postcode, $country';

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
            // Home Address
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
                    }
                  },
                )
              ],
            ),
            SizedBox(height: 24),

            // Light Sensor
            _buildSensorCard(
              icon: Icons.wb_sunny,
              label: 'Ambient Light',
              value: '--',
              unit: 'lux',
              color: Colors.yellow.shade600,
            ),
            SizedBox(height: 16),

            // Temperature Sensor
            _buildSensorCard(
              icon: Icons.thermostat,
              label: 'Temperature',
              value: '--',
              unit: '°C',
              color: Colors.redAccent,
            ),
            SizedBox(height: 16),

            // Humidity Sensor
            _buildSensorCard(
              icon: Icons.water_drop,
              label: 'Humidity',
              value: '--',
              unit: '%',
              color: Colors.blueAccent,
            ),
            SizedBox(height: 16),

            // Air Pressure Sensor
            _buildSensorCard(
              icon: Icons.speed,
              label: 'Air Pressure',
              value: '--',
              unit: 'hPa',
              color: Colors.deepPurpleAccent,
            ),
            SizedBox(height: 30),

            // Placeholder for Graph or History
            Center(
              child: Text(
                'Sensor history or charts coming soon...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
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
                  '$value $unit',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
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
              // Address Line 1
              TextFormField(
                initialValue: addressLine1,
                decoration: InputDecoration(labelText: 'Address Line 1 *'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => addressLine1 = value ?? '',
              ),
              SizedBox(height: 16),

              // Address Line 2 (optional)
              TextFormField(
                initialValue: addressLine2,
                decoration: InputDecoration(labelText: 'Street / Block (optional)'),
                onSaved: (value) => addressLine2 = value ?? '',
              ),
              SizedBox(height: 16),

              // City
              TextFormField(
                initialValue: city,
                decoration: InputDecoration(labelText: 'City *'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => city = value ?? '',
              ),
              SizedBox(height: 16),

              // Postcode
              TextFormField(
                initialValue: postcode,
                decoration: InputDecoration(labelText: 'Postcode *'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => postcode = value ?? '',
              ),
              SizedBox(height: 16),

              // Country
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
