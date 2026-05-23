import 'package:flutter/foundation.dart';

/// EV charging location shown on the map (demo or live data).
@immutable
class ChargingStation {
  const ChargingStation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.availablePorts,
    required this.totalPorts,
    required this.pricePerKwh,
    required this.rating,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int availablePorts;
  final int totalPorts;
  final double pricePerKwh;
  final double rating;
}
