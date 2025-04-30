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
  final List<Map<String, dynamic>> devices;
  final void Function(Map<String, dynamic>) onAddDevice;
  final void Function(String) onRemoveDevice;
  final void Function(String) onToggleDeviceStatus;

  DevicesPage({
    required this.devices,
    required this.onAddDevice,
    required this.onRemoveDevice,
    required this.onToggleDeviceStatus,
  });

  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  Set<String> addedNames = {};
  List<String> allDeviceNames = List<String>.from(deviceIcons.keys);

  @override
  void initState() {
    super.initState();
    addedNames = widget.devices.map((d) => d['name'] as String).toSet();
  }

  void _promptAddCustomDevice(BuildContext context) {
    String customName = '';
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Add Custom Device'),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: 'Enter device name'),
            onChanged: (value) => customName = value.trim(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (customName.isEmpty) return;
                if (allDeviceNames.contains(customName)) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Duplicate Device'),
                      content: Text('Device "$customName" already exists.'),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                    ),
                  );
                  return;
                }
                setState(() {
                  deviceIcons[customName] = Icons.device_unknown;
                  allDeviceNames.add(customName);
                  final newDevice = {
                    'name': customName,
                    'id': uuid.v4(),
                    'isOnline': false,
                  };
                  widget.onAddDevice(newDevice);
                  addedNames.add(customName);
                });
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Success'),
                    content: Text('"$customName" added successfully!'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                  ),
                );
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Devices'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to remove all devices?'),
            SizedBox(height: 12),
            Text('This action cannot be undone.', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              for (var device in List.from(widget.devices)) {
                widget.onRemoveDevice(device['id']);
              }
              setState(() {
                addedNames.clear();
              });
              Navigator.pop(context);
            },
            child: Text('Confirm'),
          )
        ],
      ),
    );
  }

  void _openDeviceDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                            final alreadyAdded = addedNames.contains(name);
                            return ListTile(
                              leading: Icon(deviceIcons[name] ?? Icons.devices_other),
                              title: Text(name),
                              trailing: ElevatedButton(
                                onPressed: alreadyAdded
                                    ? null
                                    : () {
                                        final newDevice = {
                                          'name': name,
                                          'id': uuid.v4(),
                                          'isOnline': false,
                                        };
                                        widget.onAddDevice(newDevice);
                                        setModalState(() {
                                          addedNames.add(name);
                                        });
                                        setState(() {
                                          addedNames.add(name);
                                        });
                                      },
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
                                children: [
                                  Divider(),
                                  Text('Not found your device?', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                                  SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => _promptAddCustomDevice(context),
                                    icon: Icon(Icons.add),
                                    label: Text('Add Custom Device'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Devices'),
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            tooltip: 'Clear All Devices',
            onPressed: _confirmClearAll,
          ),
        ],
      ),
      body: widget.devices.isEmpty
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
              itemCount: widget.devices.length,
              itemBuilder: (_, index) {
                final device = widget.devices[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeviceDetailPage(
                            device: device,
                            onDelete: () => widget.onRemoveDevice(device['id']),
                            onToggleStatus: () => widget.onToggleDeviceStatus(device['id']),
                          ),
                        ),
                      );
                    },
                    leading: Icon(deviceIcons[device['name']] ?? Icons.devices_other, color: Colors.blueAccent),
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
            onPressed: () => _openDeviceDrawer(context),
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to remove this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDelete();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Device removed successfully')),
              );
            },
            child: Text('Delete'),
          )
        ],
      ),
    );
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
              onPressed: _confirmDelete,
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
