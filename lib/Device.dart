import 'package:flutter/material.dart';

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