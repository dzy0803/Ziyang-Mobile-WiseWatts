import 'package:flutter/material.dart';
import 'home_page.dart';
import 'devices_page.dart';
import 'energy_hub_page.dart';
import 'bills_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),         // Home content page
    DevicesPage(),      // Devices management page
    EnergyHubPage(),    // Energy hub analytics page
    BillsPage(),        // Bills overview page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Important when 4 items
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Devices'),
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Energy Hub'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Bills'),
        ],
      ),
    );
  }
}
