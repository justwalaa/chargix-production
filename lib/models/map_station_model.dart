import '../utils/geo_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

export 'map_station.dart';

/// Compatibility helper used by older map/services code paths.
abstract final class CoordValidator {
  static bool isValid(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  static bool isValidMENA(double lat, double lng) {
    if (!isValid(lat, lng)) return false;
    return lat >= 10 && lat <= 45 && lng >= 20 && lng <= 65;
  }

  static double haversineKm(LatLng a, LatLng b) {
    return GeoUtils.distanceKm(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }
}