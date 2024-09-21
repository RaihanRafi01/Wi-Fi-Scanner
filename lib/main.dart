import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:permission_handler/permission_handler.dart';
import 'device_details_screen.dart'; // Import the new screen
import 'dart:async';

class WifiScanner extends StatefulWidget {
  @override
  _WifiScannerState createState() => _WifiScannerState();
}

class _WifiScannerState extends State<WifiScanner> {
  final NetworkInfo _networkInfo = NetworkInfo();
  String? _wifiName = '';
  String? _wifiIP = '';
  String? _subnetMask = '255.255.255.0'; // Placeholder
  String? _dns1 = '8.8.8.8'; // Placeholder
  String? _dns2 = '8.8.4.4'; // Placeholder
  List<Device> _connectedDevices = [];
  List<NetworkHistory> _networkHistory = []; // Track previous connections
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _startPolling(); // Start polling for Wi-Fi changes
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when disposing
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
      if (_wifiName != null) {
        _recordNetworkHistory(_wifiName!); // Record network history when connected
      }
    } catch (e) {
      print('Failed to get network info: $e');
    }

    setState(() {});

    if (_wifiIP != null) {
      _scanNetwork(_wifiIP!);
    }
  }

  void _scanNetwork(String deviceIP) async {
    final subnet = deviceIP.substring(0, deviceIP.lastIndexOf('.'));
    final futures = <Future>[];

    for (int i = 1; i < 255; i++) {
      final ip = '$subnet.$i';
      futures.add(_pingDevice(ip));
    }

    await Future.wait(futures);
  }

  Future<void> _pingDevice(String ip) async {
    final ping = Ping(ip, count: 1, timeout: 1000);
    await for (final PingData data in ping.stream) {
      if (data.response != null) {
        setState(() {
          _connectedDevices.add(Device(
            ip: ip,
            status: 'Active',
            name: ip, // Default name as IP
            type: _determineDeviceType(ip),
            gateway: '192.168.1.1', // Placeholder for gateway
            subnetMask: _subnetMask ?? 'Unavailable',
            dns1: _dns1 ?? 'Unavailable',
            dns2: _dns2 ?? 'Unavailable',
          ));
        });
      }
    }
  }

  String _determineDeviceType(String ip) {
    // Placeholder logic to determine device type
    if (ip.startsWith("192.168.1.")) {
      return "Mobile";
    }
    return "Generic";
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

  void _reloadDevices() {
    setState(() {
      _connectedDevices.clear();
    });
    if (_wifiIP != null) {
      _scanNetwork(_wifiIP!);
    }
  }

  void _recordNetworkHistory(String wifiName) {
    // Check if the current wifiName is already in the network history
    bool exists = _networkHistory.any((history) => history.wifiName == wifiName);

    if (!exists) {
      _networkHistory.add(NetworkHistory(
        wifiName: wifiName,
        timestamp: DateTime.now(),
        devices: List.from(_connectedDevices),
      ));
    }
  }


  void _onWifiChange() async {
    await _initNetworkInfo();
    setState(() {
      _connectedDevices.clear(); // Clear the list of connected devices
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
                  // Top Row with Wi-Fi Logo, Name, and Reload Button
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
                        onPressed: _reloadDevices,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text('Connected Devices:', style: TextStyle(fontSize: 18)),
                  Expanded(
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
                      subtitle: Text('Connected on: ${history.timestamp}'),
                      children: history.devices.map((device) {
                        return ListTile(
                          leading: Icon(device.icon ?? Icons.device_unknown, size: 40),
                          title: Text(device.name ?? device.ip),
                          subtitle: Text('Status: ${device.status}'),
                          onTap: () => _navigateToDeviceDetails(device),
                        );
                      }).toList(),
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

class Device {
  String ip;
  String status;
  String? name;
  IconData? icon;
  String type;
  String gateway;
  String subnetMask;
  String dns1;
  String dns2;

  Device({
    required this.ip,
    required this.status,
    this.name,
    this.icon,
    required this.type,
    required this.gateway,
    required this.subnetMask,
    required this.dns1,
    required this.dns2,
  });

  Device copyWith({
    String? ip,
    String? status,
    String? name,
    IconData? icon,
    String? type,
    String? gateway,
    String? subnetMask,
    String? dns1,
    String? dns2,
  }) {
    return Device(
      ip: ip ?? this.ip,
      status: status ?? this.status,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      gateway: gateway ?? this.gateway,
      subnetMask: subnetMask ?? this.subnetMask,
      dns1: dns1 ?? this.dns1,
      dns2: dns2 ?? this.dns2,
    );
  }
}

class NetworkHistory {
  final String wifiName;
  final DateTime timestamp;
  final List<Device> devices; // List of devices connected during this network session

  NetworkHistory({required this.wifiName, required this.timestamp, required this.devices});
}

void main() {
  runApp(MaterialApp(
    home: WifiScanner(),
  ));
}