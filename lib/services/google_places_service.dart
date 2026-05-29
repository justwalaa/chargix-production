import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/maps_config.dart';
import '../models/external_place_metadata.dart';
import '../models/map_station.dart';
import '../services/map/map_pipeline_logger.dart';
import '../utils/geo_utils.dart';

/// Autocomplete suggestion from Google Places.
class PlaceAutocompletePrediction {
  const PlaceAutocompletePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
}

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

    absorb(
      await searchChargingStationsByText(
        query: 'electric vehicle charging station',
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      ),
    );

    absorb(
      await searchChargingStationsByText(
        query: 'charging station',
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
    MapPipelineLogger.places(
      '${list.length} external stations near ($latitude, $longitude)',
    );
    if (list.isEmpty) {
      MapPipelineLogger.places('empty response for nearby search');
    }
    return list;
  }

  /// Address / place autocomplete (registration + map search assist).
  Future<List<PlaceAutocompletePrediction>> fetchAutocomplete({
    required String input,
    double? latitude,
    double? longitude,
    int radiusMeters = 50000,
  }) async {
    final trimmed = input.trim();
    if (trimmed.length < 2) return const [];

    final params = <String, String>{
      'input': trimmed,
      'key': MapsConfig.placesApiKey,
      'types': 'geocode|establishment',
    };
    if (latitude != null && longitude != null) {
      params['location'] = '$latitude,$longitude';
      params['radius'] = '$radiusMeters';
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      params,
    );

    final body = await _getJson(uri, context: 'autocomplete');
    if (body == null) {
      MapPipelineLogger.places('autocomplete empty/failed for "$trimmed"');
      return const [];
    }

    final predictions = body['predictions'] as List<dynamic>? ?? [];
    if (predictions.isEmpty) {
      MapPipelineLogger.places('autocomplete zero results for "$trimmed"');
    }

    return predictions
        .whereType<Map<String, dynamic>>()
        .map((p) {
          final structured = p['structured_formatting'] as Map<String, dynamic>?;
          return PlaceAutocompletePrediction(
            placeId: p['place_id'] as String? ?? '',
            description: p['description'] as String? ?? '',
            mainText: structured?['main_text'] as String? ?? '',
            secondaryText: structured?['secondary_text'] as String? ?? '',
          );
        })
        .where((p) => p.placeId.isNotEmpty)
        .toList(growable: false);
  }

  /// Resolves a place id to coordinates + formatted address.
  Future<GeocodedLocation?> fetchPlaceDetails(String placeId) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'fields': 'geometry,formatted_address,place_id,name',
        'key': MapsConfig.placesApiKey,
      },
    );

    final body = await _getJson(uri, context: 'place_details');
    if (body == null) return null;

    final result = body['result'] as Map<String, dynamic>?;
    if (result == null) return null;

    final geometry = result['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble();
    final lng = (location?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return GeocodedLocation(
      latitude: lat,
      longitude: lng,
      formattedAddress: result['formatted_address'] as String? ??
          result['name'] as String? ??
          '$lat, $lng',
      placeId: result['place_id'] as String? ?? placeId,
    );
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
      if (!_isEvChargingPlace(raw)) continue;
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
        final isTypedEvSearch = type == MapsConfig.nearbySearchType;
        if (isTypedEvSearch ||
            keyword != null ||
            _isEvChargingPlace(raw)) {
          final station = _parsePlace(raw, latitude, longitude);
          if (station != null) all.add(station);
        }
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
        MapPipelineLogger.places(
          '$context HTTP ${response.statusCode}',
        );
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? '';
      if (status == 'ZERO_RESULTS') {
        MapPipelineLogger.places('$context ZERO_RESULTS');
        return body;
      }
      if (status != 'OK') {
        MapPipelineLogger.places(
          '$context API failure: $status ${body['error_message'] ?? ''}',
        );
        return null;
      }
      return body;
    } on Object catch (e) {
      MapPipelineLogger.places('$context failed: $e');
      return null;
    }
  }

  bool _isEvChargingPlace(Map<String, dynamic> place) {
    final types = (place['types'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    if (types.contains('electric_vehicle_charging_station')) {
      return true;
    }
    final name = (place['name'] as String? ?? '').toLowerCase();
    if (name.contains('charg') ||
        name.contains('charging') ||
        name.contains('supercharger') ||
        name.contains('ev ') ||
        name.startsWith('ev ') ||
        name.endsWith(' ev')) {
      return true;
    }
    return false;
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
