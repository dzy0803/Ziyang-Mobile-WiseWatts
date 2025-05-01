
// main_page.dart
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'devices_page.dart';
import 'energy_hub_page.dart';
import 'environment_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  List<Map<String, dynamic>> devices = [];

  void _addDevice(Map<String, dynamic> device) {
    setState(() {
      devices.add(device);
    });
  }

  void _removeDevice(String id) {
    setState(() {
      devices.removeWhere((d) => d['id'] == id);
    });
  }

  void _toggleDeviceStatus(String id) {
    setState(() {
      final index = devices.indexWhere((d) => d['id'] == id);
      if (index != -1) {
        devices[index]['isOnline'] = !(devices[index]['isOnline'] as bool);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomePage(
        devices: devices,
        onViewDevices: () {
          setState(() {
            _currentIndex = 2;
          });
        },
      ),
      EnvironmentPage(),
      DevicesPage(
        devices: devices,
        onAddDevice: _addDevice,
        onRemoveDevice: _removeDevice,
        onToggleDeviceStatus: _toggleDeviceStatus,
      ),
      EnergyHubPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.sensors), label: 'Environment'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Devices'),
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Energy Hub'),
        ],
      ),
    );
  }
}