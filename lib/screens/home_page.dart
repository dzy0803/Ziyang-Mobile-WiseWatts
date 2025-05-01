import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  void _showNavigateDialog() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Credit', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
        content: Text('Do you want to go to the Top Up page?', style: TextStyle(fontSize: 18, color: Colors.black87)),
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

  @override
  Widget build(BuildContext context) {
    final totalDevices = widget.devices.length;
    final onlineDevices = widget.devices.where((d) => d['isOnline'] == true).length;

    return ChangeNotifierProvider(
      create: (_) => SensorDataModel(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.orangeAccent,
          title: Text('Welcome back, Ziyang!'),
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
                children: [
                  // Account Balance Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Account Balance:', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                          SizedBox(height: 10),
                          Center(child: Text('£${accountBalance.toStringAsFixed(2)}', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold))),
                          SizedBox(height: 20),
                          GestureDetector(
                            onTap: _showNavigateDialog,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Add credit', style: TextStyle(fontSize: 18, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                                Icon(Icons.chevron_right, color: Colors.blue.shade800),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Sensor Averages Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Avg. Sensor Readings (Last Hour)', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                          SizedBox(height: 10),
                          _buildSensorRow(Icons.wb_sunny, 'Light', model.lightAvg, 'lux'),
                          _buildSensorRow(Icons.thermostat, 'Temperature', model.tempAvg, '°C'),
                          _buildSensorRow(Icons.water_drop, 'Humidity', model.humidityAvg, '%'),
                          _buildSensorRow(Icons.speed, 'Pressure', model.pressureAvg, 'hPa'),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Devices Summary Card
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
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSensorRow(IconData icon, String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.orangeAccent),
          Text(label, style: TextStyle(fontSize: 16)),
          Text('${value.toStringAsFixed(1)} $unit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
