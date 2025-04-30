import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

final uuid = Uuid();

final Map<String, IconData> deviceIcons = {
  'Smart Fridge': Icons.kitchen,
  'Air Conditioner': Icons.ac_unit,
  'Washing Machine': Icons.local_laundry_service,
  'Heater': Icons.whatshot,
  'Smart TV': Icons.tv,
  'Microwave Oven': Icons.microwave,
  'Water Heater': Icons.hot_tub,
  'LED Lighting': Icons.lightbulb,
  'WiFi Router': Icons.router,
  'Smart Speaker': Icons.speaker,
  'Laptop Charger': Icons.power,
  'Electric Kettle': Icons.coffee,
  'Robot Vacuum': Icons.cleaning_services,
  'Dishwasher': Icons.dining,
  'Coffee Maker': Icons.local_cafe,
  'Oven': Icons.local_pizza,
  'Hair Dryer': Icons.bolt,
  'Gaming Console': Icons.sports_esports,
  'Security Camera': Icons.videocam,
  'Smart Plug': Icons.power_outlined,
  'Ceiling Fan': Icons.toys,
  'Door Sensor': Icons.sensor_door,
  'Window Sensor': Icons.sensor_window,
  'Motion Detector': Icons.sensors,
  'Smart Doorbell': Icons.doorbell,
  'Garage Opener': Icons.garage,
  'Water Leak Sensor': Icons.water_damage,
  'Air Purifier': Icons.air,
  'Baby Monitor': Icons.baby_changing_station,
  'Smart Thermostat': Icons.thermostat,
};

class DevicesPage extends StatefulWidget {
  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final List<Map<String, dynamic>> devices = [];
  final Set<String> addedDeviceNames = {};
  final List<String> allDeviceNames = deviceIcons.keys.toList();

  void _addDevice(String name) {
    setState(() {
      addedDeviceNames.add(name);
      devices.add({
        'name': name,
        'id': uuid.v4(),
        'isOnline': false,
      });
    });
    Navigator.of(context).maybePop();
  }

  void _removeDevice(String id) {
    setState(() {
      final removed = devices.firstWhere((d) => d['id'] == id);
      addedDeviceNames.remove(removed['name']);
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

  void _navigateToDetail(Map<String, dynamic> device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceDetailPage(
          device: device,
          onDelete: () => _removeDevice(device['id']),
          onToggleStatus: () => _toggleDeviceStatus(device['id']),
        ),
      ),
    );
  }

  void _promptAddCustomDevice() {
    String customName = '';
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Add Custom Device'),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: 'Enter device name'),
            onChanged: (value) {
              customName = value.trim();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (customName.isEmpty) return;
                if (allDeviceNames.contains(customName)) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Duplicate Device'),
                      content: Text('Device "$customName" already exists.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        )
                      ],
                    ),
                  );
                  return;
                }
                setState(() {
                  allDeviceNames.add(customName);
                });
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _openDeviceDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: allDeviceNames.length + 1,
                    itemBuilder: (_, index) {
                      if (index < allDeviceNames.length) {
                        final name = allDeviceNames[index];
                        final alreadyAdded = addedDeviceNames.contains(name);
                        return ListTile(
                          leading: Icon(deviceIcons[name] ?? Icons.devices_other),
                          title: Text(name),
                          trailing: ElevatedButton(
                            onPressed: alreadyAdded ? null : () => _addDevice(name),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: alreadyAdded ? Colors.grey : Colors.orangeAccent,
                            ),
                            child: Text(alreadyAdded ? 'Added' : 'Add'),
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Divider(),
                              Text(
                                'Not found your device?',
                                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              ),
                              SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _promptAddCustomDevice,
                                icon: Icon(Icons.add),
                                label: Text('Add Custom Device'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Devices'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: devices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.devices_other, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('No devices yet', style: TextStyle(fontSize: 20, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (_, index) {
                final device = devices[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    onTap: () => _navigateToDetail(device),
                    leading: Icon(
                      deviceIcons[device['name']] ?? Icons.devices_other,
                      color: Colors.blueAccent,
                    ),
                    title: Text(device['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${device['id']}'),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: device['isOnline'] ? Colors.green : Colors.grey),
                            SizedBox(width: 6),
                            Text(
                              device['isOnline'] ? 'Online' : 'Offline',
                              style: TextStyle(fontSize: 14, color: device['isOnline'] ? Colors.green : Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _openDeviceDrawer,
            backgroundColor: Colors.orangeAccent,
            child: Icon(Icons.add),
          ),
          SizedBox(height: 8),
          Text('Add Device', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class DeviceDetailPage extends StatefulWidget {
  final Map<String, dynamic> device;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  DeviceDetailPage({
    required this.device,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  _DeviceDetailPageState createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  late bool isOnline;

  @override
  void initState() {
    super.initState();
    isOnline = widget.device['isOnline'];
  }

  void _toggleStatus() {
    widget.onToggleStatus();
    setState(() {
      isOnline = !isOnline;
    });
  }

  @override
  Widget build(BuildContext context) {
    final icon = deviceIcons[widget.device['name']] ?? Icons.devices_other;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device['name']),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.orangeAccent),
            SizedBox(height: 20),
            Text(widget.device['name'], style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 16, color: isOnline ? Colors.green : Colors.grey),
                SizedBox(width: 8),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
            SizedBox(height: 30),
            Text('Device ID:', style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 6),
            SelectableText(widget.device['id'], style: TextStyle(fontSize: 16)),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _toggleStatus,
              icon: Icon(Icons.power_settings_new),
              label: Text(isOnline ? 'Turn OFF' : 'Turn ON'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOnline ? Colors.redAccent : Colors.green,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                widget.onDelete();
                Navigator.pop(context);
              },
              icon: Icon(Icons.delete),
              label: Text('Remove Device'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            )
          ],
        ),
      ),
    );
  }
}
