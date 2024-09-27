import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'Device.dart';
import 'main.dart'; // Import the main file for the Device class

class DeviceDetailsScreen extends StatefulWidget {
  final Device device;
  final ValueChanged<Device> onUpdate;

  const DeviceDetailsScreen(
      {super.key, required this.device, required this.onUpdate});

  @override
  _DeviceDetailsScreenState createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Device Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Edit Device Name'),
            ),
            const SizedBox(height: 10),
            const Text('Select Icon', style: TextStyle(fontSize: 16)),
            GestureDetector(
              onTap: () async {
                final selectedIcon = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IconSelectionScreen(
                        currentIcon: widget.device.icon ??
                            FontAwesomeIcons.mobileScreen),
                  ),
                );
                if (selectedIcon != null) {
                  setState(() {
                    widget.device.icon = selectedIcon ??
                        FontAwesomeIcons.mobileScreen; // Default icon
                  });
                }
              },
              child: Row(
                children: [
                  Icon(widget.device.icon ?? FontAwesomeIcons.mobileScreen,
                      size: 50), // Default icon
                  const SizedBox(width: 10),
                  Text(
                    _getIconName(widget.device.icon ??
                        FontAwesomeIcons.mobileScreen), // Default icon name
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailCard('Status', widget.device.status),
            _buildDetailCard('IP Address', widget.device.ip),
            _buildDetailCard('Gateway', widget.device.gateway),
            _buildDetailCard('Subnet Mask', widget.device.subnetMask),
            _buildDetailCard('DNS 1', widget.device.dns1),
            _buildDetailCard('DNS 2', widget.device.dns2),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final updatedDevice = widget.device.copyWith(
                  name: _nameController.text,
                );
                widget.onUpdate(updatedDevice);
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text('$title: ',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  String _getIconName(IconData? icon) {
    // Use a default value to avoid null
    if (icon == null) {
      return 'Default Icon'; // Or some default name
    }
    switch (icon) {
      case FontAwesomeIcons.desktop:
        return 'Desktop';
      case FontAwesomeIcons.mobileAlt:
        return 'Mobile';
      case FontAwesomeIcons.tabletAlt:
        return 'Tablet';
      case FontAwesomeIcons.tv:
        return 'TV';
      case FontAwesomeIcons.laptop:
        return 'Laptop';
      case FontAwesomeIcons.camera:
        return 'Camera';
      case FontAwesomeIcons.fax:
        return 'Printer';
      case FontAwesomeIcons.headphones:
        return 'Headphones';
      // Add more cases for other icons
      default:
        return 'Unknown Icon';
    }
  }
}

class IconSelectionScreen extends StatelessWidget {
  final IconData currentIcon;

  IconSelectionScreen({super.key, required this.currentIcon});

  final List<IconData> icons = [
    FontAwesomeIcons.desktop,
    FontAwesomeIcons.mobileAlt,
    FontAwesomeIcons.tabletAlt,
    FontAwesomeIcons.tv,
    FontAwesomeIcons.laptop,
    FontAwesomeIcons.camera,
    FontAwesomeIcons.fax,
    FontAwesomeIcons.headphones,
    // Add more icons as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Icon'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 columns
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        padding: const EdgeInsets.all(8),
        itemCount: icons.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.pop(context, icons[index]);
            },
            child: Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icons[index], size: 40),
                  const SizedBox(height: 5),
                  Text(
                    _getIconName(icons[index]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getIconName(IconData icon) {
    switch (icon) {
      case FontAwesomeIcons.desktop:
        return 'Desktop';
      case FontAwesomeIcons.mobileAlt:
        return 'Mobile';
      case FontAwesomeIcons.tabletAlt:
        return 'Tablet';
      case FontAwesomeIcons.tv:
        return 'TV';
      case FontAwesomeIcons.laptop:
        return 'Laptop';
      case FontAwesomeIcons.camera:
        return 'Camera';
      case FontAwesomeIcons.fax:
        return 'Printer';
      case FontAwesomeIcons.headphones:
        return 'Headphones';
      // Add more cases for other icons
      default:
        return 'Unknown Icon';
    }
  }
}
