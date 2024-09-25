import 'Device.dart';
import 'main.dart'; // Assuming your Device class is in device.dart

class NetworkHistory {
  final String wifiName;
   DateTime timestamp;
   List<Device> devices;

  NetworkHistory(
      {required this.wifiName, required this.timestamp, required this.devices});
}
