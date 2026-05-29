import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/map_station.dart';
import 'google_places_service.dart';

class PlacesService {
  PlacesService._();
  static final PlacesService instance = PlacesService._();

  Future<List<MapStation>> fetchNearbyEVStations({
    required LatLng center,
    double radiusMeters = 5000,
  }) {
    return GooglePlacesService.instance.fetchNearbyChargingStations(
      latitude: center.latitude,
      longitude: center.longitude,
      radiusMeters: radiusMeters.round(),
    );
  }

  Future<StationVerificationResult> verifyStation({
    required String stationName,
    required LatLng location,
  }) async {
    final nearby = await fetchNearbyEVStations(
      center: location,
      radiusMeters: 500,
    );
    final query = stationName.trim().toLowerCase();
    MapStation? matched;
    for (final station in nearby) {
      final name = station.name.toLowerCase();
      if (name.contains(query) || query.contains(name)) {
        matched = station;
        break;
      }
    }
    return StationVerificationResult(
      isVerified: matched != null,
      confidence: matched == null ? 0.0 : 0.7,
      placeId: matched?.external?.placeId ?? matched?.id,
      matchedName: matched?.name,
      notes: matched != null
          ? 'Matched station by nearby name'
          : 'No confident match found',
    );
  }
}

class StationVerificationResult {
  final bool isVerified;
  final double confidence;
  final String? placeId;
  final String? matchedName;
  final String? notes;

  const StationVerificationResult({
    required this.isVerified,
    required this.confidence,
    this.placeId,
    this.matchedName,
    this.notes,
  });
}
