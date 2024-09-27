import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Device.dart';
import 'device_details_screen.dart';
import 'dart:async';

class WifiScanner extends StatefulWidget {
  @override
  _WifiScannerState createState() => _WifiScannerState();
}

class _WifiScannerState extends State<WifiScanner> {
  final NetworkInfo _networkInfo = NetworkInfo();
  String? _wifiName;
  String? _wifiIP;
  List<Device> _connectedDevices = [];
  List<NetworkHistory> _networkHistory = [];
  Timer? _timer;
  bool _isScanning = false; // Flag to check if scanning is in progress
  final DateFormat dateFormat = DateFormat('dd MMM, hh:mm a');

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadNetworkHistory().then((_) {
      _initNetworkInfo(); // Initialize network info after loading history
    });
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _initNetworkInfo();
    } else {
      print('Location permission is denied.');
    }
  }

  Future<void> _initNetworkInfo() async {
    try {
      _wifiName = await _networkInfo.getWifiName();
      _wifiIP = await _networkInfo.getWifiIP();
      print('Connected to Wi-Fi: $_wifiName'); // Debugging print
      if (_wifiName != null && _wifiIP != null) {
        // Scan network before recording the history
        await _scanNetwork(_wifiIP!);
        await _recordNetworkHistory(_wifiName!);
      }
    } catch (e) {
      print('Failed to get network info: $e');
    }

    setState(() {});
  }

  Future<void> _scanNetwork(String deviceIP) async {
    setState(() {
      _isScanning = true;
      _connectedDevices.clear(); // Clear previous devices
    });

    final subnet = deviceIP.substring(0, deviceIP.lastIndexOf('.'));
    print('Scanning subnet: $subnet');

    Timer.periodic(Duration(seconds: 5), (timer) {
      if (_connectedDevices.isNotEmpty) {
        print('Scan completed. Found ${_connectedDevices.length} devices.');
        _recordNetworkHistory(_wifiName!); // Record network history here
        setState(() {
          _isScanning = false; // Stop scanning
        });
        timer.cancel(); // Stop the timer
      }
    });

    for (int i = 1; i < 255; i++) { // Scan the full range
      final ip = '$subnet.$i';
      _pingDevice(ip); // Call ping directly without waiting for Future
    }
  }

  Future<void> _pingDevice(String ip) async {
    final ping = Ping(ip, count: 1, timeout: 2000); // Keep it responsive
    await for (final PingData data in ping.stream) {
      if (data.response != null) {
        print('Device found: $ip');
        setState(() {
          _connectedDevices.add(Device(
            ip: ip,
            status: 'Active',
            name: ip, // Default name as IP
            type: _determineDeviceType(ip),
            gateway: '192.168.1.1', // Placeholder for gateway
            subnetMask: '255.255.255.0', // Placeholder
            dns1: '8.8.8.8', // Placeholder
            dns2: '8.8.4.4', // Placeholder
          ));
        });
      } else {
        print('No response from $ip');
      }
    }
  }




  String _determineDeviceType(String ip) {
    return ip.startsWith("192.168.1") ? "Mobile" : "Generic";
  }

  void _navigateToDeviceDetails(Device device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceDetailsScreen(
          device: device,
          onUpdate: (updatedDevice) {
            setState(() {
              final index = _connectedDevices.indexOf(device);
              if (index != -1) {
                _connectedDevices[index] = updatedDevice;
              }
            });
          },
        ),
      ),
    );
  }

  Future<void> _recordNetworkHistory(String wifiName) async {
    if (_connectedDevices.isEmpty) {
      print('No devices to record in network history.');
      return; // No devices to record
    }

    // Find if the network already exists in the history
    final existingHistoryIndex = _networkHistory.indexWhere((history) => history.wifiName == wifiName);

    if (existingHistoryIndex != -1) {
      // Update existing entry
      setState(() {
        _networkHistory[existingHistoryIndex].devices = List.from(_connectedDevices);
        _networkHistory[existingHistoryIndex].timestamp = DateTime.now();
      });
    } else {
      // Create and add new history entry
      NetworkHistory newHistory = NetworkHistory(
        wifiName: wifiName,
        timestamp: DateTime.now(),
        devices: List.from(_connectedDevices),
      );

      setState(() {
        _networkHistory.add(newHistory);
      });
    }

    // Save the updated history to SharedPreferences
    await _saveNetworkHistory();
  }

  // Function to save network history to SharedPreferences
  Future<void> _saveNetworkHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> histories = _networkHistory.map((history) => newHistoryToJson(history)).toList();
    bool isSaved = await prefs.setStringList('network_history', histories);

    if (isSaved) {
      print('Network history saved successfully.');
    } else {
      print('Failed to save network history.');
    }
  }

  // Function to load network history from SharedPreferences
  Future<void> _loadNetworkHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? histories = prefs.getStringList('network_history');

    if (histories != null) {
      setState(() {
        _networkHistory = histories.map((json) => jsonToNetworkHistory(json)).toList();
      });
      print('Loaded network history: $_networkHistory'); // Debugging output
    } else {
      print('No network history found.');
    }
  }

  String newHistoryToJson(NetworkHistory history) {
    return jsonEncode({
      'wifiName': history.wifiName,
      'timestamp': history.timestamp.toIso8601String(),
      'devices': history.devices.map((device) => deviceToJson(device)).toList(),
    });
  }

  String deviceToJson(Device device) {
    return jsonEncode({
      'ip': device.ip,
      'status': device.status,
      'name': device.name,
      'icon': device.icon?.codePoint,
      'type': device.type,
      'gateway': device.gateway,
      'subnetMask': device.subnetMask,
      'dns1': device.dns1,
      'dns2': device.dns2,
    });
  }

  NetworkHistory jsonToNetworkHistory(String json) {
    Map<String, dynamic> data = jsonDecode(json);
    List<Device> devices = (data['devices'] as List).map((d) => jsonToDevice(d)).toList();
    return NetworkHistory(
      wifiName: data['wifiName'],
      timestamp: DateTime.parse(data['timestamp']),
      devices: devices,
    );
  }

  Device jsonToDevice(Map<String, dynamic> json) {
    return Device(
      ip: json['ip'],
      status: json['status'],
      name: json['name'],
      icon: json['icon'] != null ? IconData(json['icon'], fontFamily: 'MaterialIcons') : null,
      type: json['type'],
      gateway: json['gateway'],
      subnetMask: json['subnetMask'],
      dns1: json['dns1'],
      dns2: json['dns2'],
    );
  }

  void _onWifiChange() async {
    await _initNetworkInfo();
    setState(() {
      _connectedDevices.clear(); // Clear devices for new network
    });
  }

  void _startPolling() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      String? newWifiName = await _networkInfo.getWifiName();
      if (newWifiName != _wifiName) {
        _wifiName = newWifiName;
        _onWifiChange();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Wi-Fi Network Info'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Devices'),
              Tab(text: 'Network History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Devices Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wifi, size: 40),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _wifiName ?? 'Unavailable',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () {
                          if (_wifiIP != null) {
                            _scanNetwork(_wifiIP!);
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _isScanning
                      ? Center(child: CircularProgressIndicator()) // Show loading indicator during scanning
                      : _connectedDevices.isEmpty
                      ? Center(child: Text('No devices found.')) // Show message if no devices are found
                      : Expanded(
                    child: ListView.builder(
                      itemCount: _connectedDevices.length,
                      itemBuilder: (context, index) {
                        final device = _connectedDevices[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: Icon(device.icon ?? Icons.device_unknown, size: 40),
                            title: Text(device.name ?? device.ip, style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Status: ${device.status}\nType: ${device.type}'),
                            onTap: () => _navigateToDeviceDetails(device),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Network History Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: _networkHistory.length,
                itemBuilder: (context, index) {
                  final history = _networkHistory[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ExpansionTile(
                      title: Text(history.wifiName),
                      subtitle: Text('Connected on: ${dateFormat.format(history.timestamp)}'),
                      children: history.devices.isNotEmpty
                          ? history.devices.map((device) {
                        return ListTile(
                          leading: Icon(device.icon ?? Icons.device_unknown, size: 40),
                          title: Text(device.name ?? device.ip),
                          subtitle: Text('Status: ${device.status}'),
                          onTap: () => _navigateToDeviceDetails(device),
                        );
                      }).toList()
                          : [ListTile(title: Text('No devices connected'))],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NetworkHistory {
  final String wifiName;
  DateTime timestamp;
  List<Device> devices;

  NetworkHistory({required this.wifiName, required this.timestamp, required this.devices});
}

void main() {
  runApp(MaterialApp(
    home: WifiScanner(),
  ));
}
