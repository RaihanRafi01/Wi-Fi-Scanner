import 'main.dart'; // Assuming your Device class is in device.dart

class NetworkHistory {
  final String wifiName;
  final DateTime timestamp;
  final List<Device> devices;

  NetworkHistory({required this.wifiName, required this.timestamp, required this.devices});

}
