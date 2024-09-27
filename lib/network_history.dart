import 'Device.dart';

class NetworkHistory {
  final String wifiName;
   DateTime timestamp;
   List<Device> devices;

  NetworkHistory(
      {required this.wifiName, required this.timestamp, required this.devices});
}
