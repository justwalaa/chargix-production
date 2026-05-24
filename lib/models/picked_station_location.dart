import 'package:flutter/foundation.dart';

/// Station location chosen on the map picker during registration.
@immutable
class PickedStationLocation {
  const PickedStationLocation({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.googlePlaceId,
    this.placeName,
  });

  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String? googlePlaceId;
  final String? placeName;
}
