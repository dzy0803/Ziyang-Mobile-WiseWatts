import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_settings/app_settings.dart';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';



void openWiFiSettings() {
  if (Platform.isAndroid) {
    final intent = AndroidIntent(
      action: 'android.settings.WIFI_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    intent.launch();
  } else {
    // Optional: handle iOS case
    print("iOS does not support direct Wi-Fi intent");
  }
}

final uuid = Uuid();

final Map<String, IconData> deviceIcons = {
  'Smart Fridge (RED LED)': Icons.kitchen,
  'Air Conditioner (GREEN LED)': Icons.ac_unit,
  'Washing Machine (YELLOW LED)': Icons.local_laundry_service,
  'Heater' : Icons.whatshot,
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
  List<String> allDeviceNames = List<String>.from(deviceIcons.keys);
  final Map<String, String> fixedDeviceIds = {
  'Smart Fridge (RED LED)': '000000',
  'Air Conditioner (GREEN LED)': '000001',
  'Washing Machine (YELLOW LED)': '000010',
  'Heater': '000011',
  'Smart TV': '000100',
  'Microwave Oven': '000101',
  'Water Heater': '000110',
  'LED Lighting': '000111',
  'WiFi Router': '001000',
  'Smart Speaker': '001001',
  'Laptop Charger': '001010',
  'Electric Kettle': '001011',
  'Robot Vacuum': '001100',
  'Dishwasher': '001101',
  'Coffee Maker': '001110',
  'Oven': '001111',
  'Hair Dryer': '010000',
  'Gaming Console': '010001',
  'Security Camera': '010010',
  'Smart Plug': '010011',
  'Ceiling Fan': '010100',
  'Door Sensor': '010101',
  'Window Sensor': '010110',
  'Motion Detector': '010111',
  'Smart Doorbell': '011000',
  'Garage Opener': '011001',
  'Water Leak Sensor': '011010',
  'Air Purifier': '011011',
  'Baby Monitor': '011100',
  'Smart Thermostat': '011101',
};

Future<void> _addDevice(String name) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final id = fixedDeviceIds[name] ?? uuid.v4(); // use fixed ID 

  final newDevice = {
    'id': id,
    'name': name,
    'isOnline': false,
    'createdAt': FieldValue.serverTimestamp(),
    'ownerId': user.uid,
  };

  await FirebaseFirestore.instance.collection('devices').doc(id).set(newDevice);
}


  Future<void> _removeDevice(String id) async {
    await FirebaseFirestore.instance.collection('devices').doc(id).delete();
  }

  Future<void> _toggleDeviceStatus(String id, bool newStatus) async {
    await FirebaseFirestore.instance.collection('devices').doc(id).update({'isOnline': newStatus});
  }


  //bluetooth connection
 Future<void> _scanAndConnectBluetoothDevice() async {
  await Permission.bluetoothScan.request();
  await Permission.bluetoothConnect.request();
  await Permission.location.request();

  FlutterBluePlus.startScan(timeout: Duration(seconds: 6));

  FlutterBluePlus.scanResults.listen((results) async {
    for (ScanResult result in results) {
      final device = result.device;
      if (device.name.contains("ESP32")) {
        FlutterBluePlus.stopScan();
        await _connectAndRegister(device);
        break;
      }
    }
  });
}


Future<void> _connectAndRegister(BluetoothDevice device) async {
  try {
    // Step 1: ask for custom name
    final customNameController = TextEditingController();
    final customName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Name your device'),
          content: TextField(
            controller: customNameController,
            decoration: InputDecoration(hintText: 'e.g. Smart Plug'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = customNameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (customName == null || customName.isEmpty) return;

    // Step 2: show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text("Registering device...")),
          ],
        ),
      ),
    );

    // Step 3: BLE connect
    await device.connect(autoConnect: false);
    List<BluetoothService> services = await device.discoverServices();

    final targetService = services.firstWhere(
      (s) => s.uuid.toString().toLowerCase().contains("12345678"),
      orElse: () => throw Exception("Target service not found"),
    );

    final targetChar = targetService.characteristics.firstWhere(
      (c) => c.uuid.toString().toLowerCase().contains("abcd1234"),
      orElse: () => throw Exception("Target characteristic not found"),
    );

    // Step 4: generate ID and send to ESP32
    final docRef = FirebaseFirestore.instance.collection('devices').doc();
    final deviceId = docRef.id;
    final payload = '$deviceId::$customName';
    await targetChar.write(utf8.encode(payload));
    await Future.delayed(Duration(milliseconds: 300));

    final currentUser = FirebaseAuth.instance.currentUser;
    await docRef.set({
      'id': deviceId,
      'name': customName,
      'ownerId': currentUser?.uid,
      'btAddress': device.id.id,
      'type': 'bluetooth',
      'isOnline': true,
    });

    await device.disconnect();

        // Step 5: close loading and show snackbar
    if (Navigator.canPop(context)) Navigator.pop(context); // Close loading
    if (Navigator.canPop(context)) Navigator.pop(context); // Close drawer

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Device "$customName" added successfully')),
    );

    setState(() {}); // Optional: refresh UI

  } catch (e) {
    if (Navigator.canPop(context)) Navigator.pop(context); // close loading
    print("Error in connectAndRegister: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Failed to add device: $e')),
    );
  }
}




// bluetooth connection area bottom

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Devices'),
        content: Text('Are you sure you want to remove all your devices?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              final snapshot = await FirebaseFirestore.instance
                  .collection('devices')
                  .where('ownerId', isEqualTo: uid)
                  .get();
              for (var doc in snapshot.docs) {
                await doc.reference.delete();
              }
              Navigator.pop(context);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

void _promptAddCustomDevice(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Choose Connection Type'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.bluetooth),
            title: Text('Bluetooth'),
            onTap: () {
              Navigator.pop(context); // close dialog
              _showBluetoothDeviceList(); // show available devices
            },
          ),
         ListTile(
  leading: Icon(Icons.wifi),
  title: Text('Wi-Fi'),
  onTap: () async {
    Navigator.pop(context);

    // 1.wifi connection to the arduino nano esp32 device

await showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('Connect to Devices              via Wi-Fi'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Please go to system Wi-Fi settings and connect to the network with your device hotspot name, e.g."Arduino_Nano_ESP32", then return.',
        ),
        SizedBox(height: 12),
        Text(
          '⚠️ Otherwise, the connection will fail.',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ],
    ),
   actions: [
 TextButton(
  onPressed: () => openWiFiSettings(),
  child: Text('Go to Wi-Fi Settings'),
),
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: Text('OK'),
  ),
],

  ),
);


    // 2. rename the device
    final nameController = TextEditingController();
    final customName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Name your device'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: 'e.g. Smart Plug'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) Navigator.pop(context, name);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (customName == null || customName.isEmpty) return;

    // 3. sned request to Arduino NANO ESP32
    final response = await http.post(
      Uri.parse('http://192.168.4.1/register'),
      body: {'name': customName},
    );

    if (response.statusCode == 200) {
      // 4. ADD this device to Firebase
      final user = FirebaseAuth.instance.currentUser;
      final deviceId = uuid.v4();
      await FirebaseFirestore.instance.collection('devices').doc(deviceId).set({
        'id': deviceId,
        'name': customName,
        'ownerId': user?.uid,
        'type': 'wifi',
        'isOnline': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Device "$customName" added')));
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Failed to register device')));
    }
  },
),

        ],
      ),
    ),
  );
}

void _showWifiDeviceList() async {
  // Step 1: Show scanning dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Expanded(child: Text("Scanning for Wi-Fi devices...")),
        ],
      ),
    ),
  );

  // Step 2: Wait a moment to simulate scanning
  await Future.delayed(Duration(seconds: 2));
  Navigator.pop(context); // Close scanning dialog

  // Step 3: Simulated Wi-Fi device list
  final wifiDevices = [
    {'ssid': 'ESP32_SETUP_001', 'ip': '192.168.4.1'},
    {'ssid': 'ESP32_SETUP_002', 'ip': '192.168.4.1'}, // static IP
  ];

  // Step 4: Show device selection list
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Select a Wi-Fi Device'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: wifiDevices.length,
          itemBuilder: (_, index) {
            final device = wifiDevices[index];
            return ListTile(
              title: Text(device['ssid']!),
              subtitle: Text('IP: ${device['ip']}'),
              onTap: () {
                Navigator.pop(context); // close list
                _connectAndRegisterWiFi(device['ip']!);
              },
            );
          },
        ),
      ),
    ),
  );
}

Future<void> _connectAndRegisterWiFi(String ip) async {
  try {
    // Step 1: Ask for device name
    final nameController = TextEditingController();
    final customName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Name your device'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: 'e.g. Smart Plug'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) Navigator.pop(context, name);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (customName == null || customName.isEmpty) return;

    // Step 2: Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text("Registering device...")),
          ],
        ),
      ),
    );

    // Step 3: Send request to ESP32
    final response = await http.post(
      Uri.parse('http://$ip/register'),
      body: {'name': customName},
    );

    if (response.statusCode == 200) {
      // Step 4: Add to Firebase
      final user = FirebaseAuth.instance.currentUser;
      final deviceId = uuid.v4();
      await FirebaseFirestore.instance.collection('devices').doc(deviceId).set({
        'id': deviceId,
        'name': customName,
        'ownerId': user?.uid,
        'type': 'wifi',
        'isOnline': true,
      });

      if (Navigator.canPop(context)) Navigator.pop(context); // close loading
      if (Navigator.canPop(context)) Navigator.pop(context); // close drawer

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Device "$customName" added')),
      );

      setState(() {}); // Refresh list
    } else {
      if (Navigator.canPop(context)) Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to register device')),
      );
    }
  } catch (e) {
    if (Navigator.canPop(context)) Navigator.pop(context); // close loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Error: $e')),
    );
  }
}


void _showBluetoothDeviceList() async {
 
  await Permission.bluetoothScan.request();
  await Permission.bluetoothConnect.request();
  await Permission.location.request();


  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Expanded(child: Text("Scanning for Bluetooth devices...")),
        ],
      ),
    ),
  );

 
  FlutterBluePlus.startScan(timeout: Duration(seconds: 3));
  await Future.delayed(Duration(seconds: 3));
  FlutterBluePlus.stopScan();
  Navigator.pop(context); 


  List<ScanResult> results = await FlutterBluePlus.scanResults.first;


  final filtered = results.where((r) =>
    r.advertisementData.localName.isNotEmpty || r.device.name.isNotEmpty
  ).toList();


  for (ScanResult r in results) {
    print("Found device:");
    print(" - name: ${r.device.name}");
    print(" - localName: ${r.advertisementData.localName}");
    print(" - id: ${r.device.id.id}");
  }


  if (filtered.isEmpty) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('No devices found'),
        content: Text('Make sure your ESP32 is powered and advertising.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
      ),
    );
    return;
  }


  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Select a Bluetooth Device'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: filtered.length,
          itemBuilder: (_, index) {
            final result = filtered[index];
            final device = result.device;
            final name = result.advertisementData.localName.isNotEmpty
              ? result.advertisementData.localName
              : device.name;

            return ListTile(
              title: Text(name),
              subtitle: Text(device.id.id),
              onTap: () {
                Navigator.pop(context); 
                _connectAndRegister(device); 
              },
            );
          },
        ),
      ),
    ),
  );
}


  void _openDeviceDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) {
          return Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('devices')
                      .where('ownerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final addedNames = snapshot.hasData
                        ? snapshot.data!.docs.map((doc) => doc['name'] as String).toSet()
                        : <String>{};
                    return ListView.builder(
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
                              onPressed: alreadyAdded ? null : () async => await _addDevice(name),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: alreadyAdded ? Colors.grey : Colors.orangeAccent),
                              child: Text(alreadyAdded ? 'Added' : 'Add'),
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
                            child: Column(
                              children: [
                                Divider(),
                                Text('Not found your device?'),
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
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('devices')
            .where('ownerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final devices = snapshot.data!.docs;
          if (devices.isEmpty) {
            return Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.devices_other, size: 100, color: Colors.grey.shade400),
      SizedBox(height: 20),
      Text(
        'No Devices Added',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[700]),
      ),
      SizedBox(height: 12),
      Text(
        'You haven\'t added any devices yet.\nTap the "+" button to get started.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      SizedBox(height: 24),
    ],
  ),
);

          }
          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (_, index) {
              final device = devices[index].data() as Map<String, dynamic>;
              final id = devices[index].id;
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
  onDelete: () => _removeDevice(id),
  onToggleStatus: (bool newStatus) => _toggleDeviceStatus(id, newStatus),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDeviceDrawer(context),
        backgroundColor: Colors.orangeAccent,
        child: Icon(Icons.add),
      ),
    );
  }
}

class DeviceDetailPage extends StatefulWidget {
  final Map<String, dynamic> device;
  final VoidCallback onDelete;
  final Future<void> Function(bool newStatus) onToggleStatus;

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
    isOnline = widget.device['isOnline'] ?? false;
  }

  Future<void> _handleToggle() async {
  final newStatus = !isOnline;
  setState(() {
    isOnline = newStatus;
  });

  await widget.onToggleStatus(newStatus);

  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text("Applying changes..."),
        ],
      ),
    ),
  );

  await Future.delayed(Duration(seconds: 1));

  if (mounted) {
    Navigator.pop(context); 
    Navigator.pop(context); 
  }
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
                Text(isOnline ? 'Online' : 'Offline', style: TextStyle(fontSize: 20)),
              ],
            ),
            SizedBox(height: 30),
            Text('Device ID:', style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 6),
            SelectableText(widget.device['id'], style: TextStyle(fontSize: 16)),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _handleToggle,
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