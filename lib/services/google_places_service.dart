import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/maps_config.dart';
import '../models/external_place_metadata.dart';
import '../models/map_station.dart';
import '../utils/geo_utils.dart';

/// Geocoded coordinates for an address string.
class GeocodedLocation {
  const GeocodedLocation({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.placeId,
  });

  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String? placeId;
}

/// Fetches nearby EV chargers from Google Places (read-only, not Firestore).
class GooglePlacesService {
  GooglePlacesService({http.Client? client}) : _client = client ?? http.Client();

  static final GooglePlacesService instance = GooglePlacesService();

  final http.Client _client;

  /// Nearby EV chargers — merges typed search, keyword search, and pagination.
  Future<List<MapStation>> fetchNearbyChargingStations({
    required double latitude,
    required double longitude,
    int radiusMeters = MapsConfig.nearbySearchRadiusMeters,
  }) async {
    final byId = <String, MapStation>{};

    void absorb(List<MapStation> batch) {
      for (final s in batch) {
        final key = s.external?.placeId ?? s.id;
        byId.putIfAbsent(key, () => s);
      }
    }

    absorb(
      await _nearbySearch(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        type: MapsConfig.nearbySearchType,
      ),
    );

    absorb(
      await _nearbySearch(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        keyword: 'electric vehicle charging station',
      ),
    );

    absorb(
      await searchChargingStationsByText(
        query: 'EV charging station',
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      ),
    );

    final list = byId.values.toList(growable: false);
    list.sort(
      (a, b) => (a.distanceKm ?? double.infinity)
          .compareTo(b.distanceKm ?? double.infinity),
    );
    debugPrint(
      'Chargix Places: ${list.length} external stations near '
      '($latitude, $longitude)',
    );
    return list;
  }

  Future<List<MapStation>> searchChargingStationsByText({
    required String query,
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
  }) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/textsearch/json',
      {
        'query': query,
        'location': '$latitude,$longitude',
        'radius': '$radiusMeters',
        'key': MapsConfig.placesApiKey,
      },
    );

    final body = await _getJson(uri, context: 'textsearch');
    if (body == null) return [];

    final results = body['results'] as List<dynamic>? ?? [];
    final stations = <MapStation>[];
    for (final raw in results) {
      if (raw is! Map<String, dynamic>) continue;
      final types = (raw['types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final isCharging = types.contains('electric_vehicle_charging_station') ||
          types.contains('gas_station') ||
          query.toLowerCase().contains('charg');
      if (!isCharging && types.isNotEmpty) {
        final name = (raw['name'] as String? ?? '').toLowerCase();
        if (!name.contains('charg') && !name.contains('ev')) {
          continue;
        }
      }
      final station = _parsePlace(raw, latitude, longitude);
      if (station != null) stations.add(station);
    }
    return stations;
  }

  /// Reverse geocode map coordinates to a formatted address.
  Future<GeocodedLocation?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'latlng': '$latitude,$longitude',
        'key': MapsConfig.placesApiKey,
      },
    );

    final body = await _getJson(uri, context: 'reverse_geocode');
    if (body == null) return null;

    final results = body['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) return null;

    final first = results.first as Map<String, dynamic>;
    final geometry = first['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble() ?? latitude;
    final lng = (location?['lng'] as num?)?.toDouble() ?? longitude;

    return GeocodedLocation(
      latitude: lat,
      longitude: lng,
      formattedAddress:
          first['formatted_address'] as String? ?? '$latitude, $longitude',
      placeId: first['place_id'] as String?,
    );
  }

  Future<GeocodedLocation?> geocodeAddress(String address) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'address': address,
        'key': MapsConfig.placesApiKey,
      },
    );

    final body = await _getJson(uri, context: 'geocode');
    if (body == null) return null;

    final results = body['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) return null;

    final first = results.first as Map<String, dynamic>;
    final geometry = first['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble();
    final lng = (location?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return GeocodedLocation(
      latitude: lat,
      longitude: lng,
      formattedAddress:
          first['formatted_address'] as String? ?? address,
      placeId: first['place_id'] as String?,
    );
  }

  Future<List<MapStation>> _nearbySearch({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String? type,
    String? keyword,
  }) async {
    final params = <String, String>{
      'location': '$latitude,$longitude',
      'radius': '$radiusMeters',
      'key': MapsConfig.placesApiKey,
    };
    if (type != null && type.isNotEmpty) {
      params['type'] = type;
    }
    if (keyword != null && keyword.isNotEmpty) {
      params['keyword'] = keyword;
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/nearbysearch/json',
      params,
    );

    final all = <MapStation>[];
    String? pageToken;
    var pages = 0;

    do {
      final queryUri = pageToken == null
          ? uri
          : uri.replace(
              queryParameters: {
                ...uri.queryParameters,
                'pagetoken': pageToken,
              },
            );

      if (pageToken != null) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }

      final body = await _getJson(queryUri, context: 'nearbysearch');
      if (body == null) break;

      final results = body['results'] as List<dynamic>? ?? [];
      for (final raw in results) {
        if (raw is! Map<String, dynamic>) continue;
        final station = _parsePlace(raw, latitude, longitude);
        if (station != null) all.add(station);
      }

      pageToken = body['next_page_token'] as String?;
      pages++;
    } while (pageToken != null && pages < MapsConfig.maxPlacesPages);

    return all;
  }

  Future<Map<String, dynamic>?> _getJson(Uri uri, {required String context}) async {
    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 18));
      if (response.statusCode != 200) {
        debugPrint(
          'Chargix Places $context: HTTP ${response.statusCode}',
        );
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? '';
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        debugPrint(
          'Chargix Places $context: $status '
          '${body['error_message'] ?? ''}',
        );
        return null;
      }
      return body;
    } on Object catch (e) {
      debugPrint('Chargix Places $context failed: $e');
      return null;
    }
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

    final vicinity = place['vicinity'] as String? ??
        place['formatted_address'] as String? ??
        '';
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
            : 'EV charging';

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
