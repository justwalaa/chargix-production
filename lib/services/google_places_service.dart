import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/maps_config.dart';
import '../models/external_place_metadata.dart';
import '../models/map_station.dart';
import '../utils/geo_utils.dart';

/// Fetches nearby EV chargers from Google Places (read-only, not Firestore).
class GooglePlacesService {
  GooglePlacesService({http.Client? client}) : _client = client ?? http.Client();

  static final GooglePlacesService instance = GooglePlacesService();

  final http.Client _client;

  Future<List<MapStation>> fetchNearbyChargingStations({
    required double latitude,
    required double longitude,
    int radiusMeters = MapsConfig.nearbySearchRadiusMeters,
  }) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/nearbysearch/json',
      {
        'location': '$latitude,$longitude',
        'radius': '$radiusMeters',
        'type': MapsConfig.nearbySearchType,
        'key': MapsConfig.placesApiKey,
      },
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      return [];
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String? ?? '';
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      return [];
    }

    final results = body['results'] as List<dynamic>? ?? [];
    final stations = <MapStation>[];

    for (final raw in results) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      final station = _parsePlace(raw, latitude, longitude);
      if (station != null) {
        stations.add(station);
      }
    }
    return stations;
  }

  MapStation? _parsePlace(
    Map<String, dynamic> place,
    double userLat,
    double userLng,
  ) {
    final placeId = place['place_id'] as String?;
    final name = place['name'] as String?;
    final geometry = place['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble();
    final lng = (location?['lng'] as num?)?.toDouble();
    if (placeId == null || name == null || lat == null || lng == null) {
      return null;
    }

    final vicinity = place['vicinity'] as String? ?? '';
    final rating = (place['rating'] as num?)?.toDouble();
    final total = (place['user_ratings_total'] as num?)?.toInt();
    final openNow = (place['opening_hours'] as Map<String, dynamic>?)?['open_now']
        as bool?;
    final businessStatus = place['business_status'] as String?;

    final types = (place['types'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final chargerHint = types.contains('electric_vehicle_charging_station')
        ? 'EV charging'
        : types.isNotEmpty
            ? types.first.replaceAll('_', ' ')
            : null;

    final km = GeoUtils.distanceKm(userLat, userLng, lat, lng);

    return MapStation.external(
      id: placeId,
      name: name,
      address: vicinity.isEmpty ? name : vicinity,
      latitude: lat,
      longitude: lng,
      distanceKm: km,
      external: ExternalPlaceMetadata(
        placeId: placeId,
        rating: rating,
        userRatingsTotal: total,
        chargerTypeHint: chargerHint,
        isOpenNow: openNow,
        businessStatus: businessStatus,
      ),
    );
  }
}
