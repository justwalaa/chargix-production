import 'package:flutter/foundation.dart';

import '../utils/geo_utils.dart';
import 'google_places_service.dart';

/// Result of matching a registering station against Google Places / Maps listings.
class StationPlacesVerificationResult {
  const StationPlacesVerificationResult({
    required this.isVerifiedOnGoogle,
    required this.confidence,
    this.matchedPlaceId,
    this.matchedName,
    this.latitude,
    this.longitude,
    this.formattedAddress,
    this.reason,
  });

  final bool isVerifiedOnGoogle;
  final double confidence;
  final String? matchedPlaceId;
  final String? matchedName;
  final double? latitude;
  final double? longitude;
  final String? formattedAddress;
  final String? reason;
}

/// Semi-automatic station approval when a real public charging listing exists on Google.
class StationPlacesVerificationService {
  StationPlacesVerificationService({GooglePlacesService? places})
      : _places = places ?? GooglePlacesService.instance;

  static final StationPlacesVerificationService instance =
      StationPlacesVerificationService();

  final GooglePlacesService _places;

  /// Legacy address-based verification (kept for compatibility).
  Future<StationPlacesVerificationResult> verifyRegistration({
    required String stationName,
    required String address,
  }) async {
    final geo = await _places.geocodeAddress(address);
    if (geo == null) {
      return const StationPlacesVerificationResult(
        isVerifiedOnGoogle: false,
        confidence: 0,
        reason: 'Could not geocode station address.',
      );
    }
    return verifyAtCoordinates(
      stationName: stationName,
      latitude: geo.latitude,
      longitude: geo.longitude,
      formattedAddress: geo.formattedAddress,
      googlePlaceId: geo.placeId,
    );
  }

  /// Primary verification path — uses map-picked coordinates.
  Future<StationPlacesVerificationResult> verifyAtCoordinates({
    required String stationName,
    required double latitude,
    required double longitude,
    String? formattedAddress,
    String? googlePlaceId,
  }) async {
    final trimmedName = stationName.trim();
    if (trimmedName.isEmpty) {
      return const StationPlacesVerificationResult(
        isVerifiedOnGoogle: false,
        confidence: 0,
        reason: 'Missing station name.',
      );
    }

    try {
      final reverse = formattedAddress == null || formattedAddress.isEmpty
          ? await _places.reverseGeocode(
              latitude: latitude,
              longitude: longitude,
            )
          : null;
      final address =
          formattedAddress ?? reverse?.formattedAddress ?? '$latitude, $longitude';

      final nearby = await _places.fetchNearbyChargingStations(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: 800,
      );

      final textMatches = await _places.searchChargingStationsByText(
        query: trimmedName,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: 1000,
      );

      final candidates = <_Candidate>[];

      if (googlePlaceId != null && googlePlaceId.isNotEmpty) {
        candidates.add(
          _Candidate(
            placeId: googlePlaceId,
            name: trimmedName,
            lat: latitude,
            lng: longitude,
            distanceKm: 0,
            fromPin: true,
          ),
        );
      }

      for (final s in [...nearby, ...textMatches]) {
        final placeId = s.external?.placeId ?? s.id;
        candidates.add(
          _Candidate(
            placeId: placeId,
            name: s.name,
            lat: s.latitude,
            lng: s.longitude,
            distanceKm: s.distanceKm ??
                GeoUtils.distanceKm(latitude, longitude, s.latitude, s.longitude),
          ),
        );
      }

      if (candidates.isEmpty) {
        return StationPlacesVerificationResult(
          isVerifiedOnGoogle: false,
          confidence: 0,
          latitude: latitude,
          longitude: longitude,
          formattedAddress: address,
          reason: 'No public charging listing found near pinned location.',
        );
      }

      _Candidate? best;
      var bestScore = 0.0;
      for (final c in candidates) {
        final score = _scoreMatch(
          stationName: trimmedName,
          candidateName: c.name,
          distanceKm: c.distanceKm,
          fromPin: c.fromPin,
        );
        if (score > bestScore) {
          bestScore = score;
          best = c;
        }
      }

      final verified = best != null && bestScore >= 0.58;
      debugPrint(
        'Chargix PlacesVerify: "$trimmedName" @($latitude,$longitude) '
        'score=${bestScore.toStringAsFixed(2)} verified=$verified',
      );

      return StationPlacesVerificationResult(
        isVerifiedOnGoogle: verified,
        confidence: bestScore,
        matchedPlaceId: best?.placeId ?? googlePlaceId,
        matchedName: best?.name,
        latitude: latitude,
        longitude: longitude,
        formattedAddress: address,
        reason: verified
            ? 'Matched public charging listing near pinned coordinates.'
            : 'No confident Google Maps match — manual review required.',
      );
    } on Object catch (e, st) {
      debugPrint('Chargix PlacesVerify failed: $e\n$st');
      return StationPlacesVerificationResult(
        isVerifiedOnGoogle: false,
        confidence: 0,
        latitude: latitude,
        longitude: longitude,
        formattedAddress: formattedAddress,
        reason: 'Verification unavailable: $e',
      );
    }
  }

  static double _scoreMatch({
    required String stationName,
    required String candidateName,
    required double distanceKm,
    bool fromPin = false,
  }) {
    final a = _normalize(stationName);
    final b = _normalize(candidateName);
    if (a.isEmpty || b.isEmpty) return fromPin ? 0.7 : 0;

    var nameScore = 0.0;
    if (a == b) {
      nameScore = 1;
    } else if (a.contains(b) || b.contains(a)) {
      nameScore = 0.88;
    } else {
      final aTokens = a.split(' ').where((t) => t.length > 2).toSet();
      final bTokens = b.split(' ').where((t) => t.length > 2).toSet();
      if (aTokens.isNotEmpty && bTokens.isNotEmpty) {
        final overlap = aTokens.intersection(bTokens).length;
        nameScore = overlap / aTokens.length.clamp(1, 99);
      }
    }

    final distanceScore = distanceKm <= 0.05
        ? 1.0
        : distanceKm <= 0.12
            ? 0.92
            : distanceKm <= 0.25
                ? 0.8
                : distanceKm <= 0.5
                    ? 0.55
                    : distanceKm <= 0.9
                        ? 0.3
                        : 0.1;

    final pinBoost = fromPin ? 0.12 : 0.0;
    return ((nameScore * 0.62) + (distanceScore * 0.38) + pinBoost).clamp(0, 1);
  }

  static String _normalize(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s\u0600-\u06FF]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _Candidate {
  const _Candidate({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    this.fromPin = false,
  });

  final String placeId;
  final String name;
  final double lat;
  final double lng;
  final double distanceKm;
  final bool fromPin;
}
