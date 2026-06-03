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

  /// Nearby EV chargers via Places API (New) — strict includedTypes filter,
  /// eliminates false positives from text/keyword searches.
  Future<List<MapStation>> fetchNearbyChargingStations({
    required double latitude,
    required double longitude,
    int radiusMeters = MapsConfig.nearbySearchRadiusMeters,
  }) async {
    final stations = await _nearbySearchNew(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
    MapPipelineLogger.places(
      '${stations.length} external stations near ($latitude, $longitude)',
    );
    if (stations.isEmpty) {
      MapPipelineLogger.places('zero EV chargers from Places API (New)');
    }
    return stations;
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

  /// Text search by name — used by verification flow to confirm a specific
  /// station name exists on Google Maps near given coordinates.
  /// Not used for generic "find all chargers" queries.
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
      final placeId = raw['place_id'] as String?;
      final name = raw['name'] as String?;
      final geometry = raw['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      final lat = (location?['lat'] as num?)?.toDouble();
      final lng = (location?['lng'] as num?)?.toDouble();
      if (placeId == null || name == null || lat == null || lng == null) {
        continue;
      }
      final km = GeoUtils.distanceKm(latitude, longitude, lat, lng);
      stations.add(
        MapStation.external(
          id: placeId,
          name: name,
          address: raw['formatted_address'] as String? ??
              raw['vicinity'] as String? ??
              name,
          latitude: lat,
          longitude: lng,
          distanceKm: km,
          external: ExternalPlaceMetadata(placeId: placeId),
        ),
      );
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

  Future<List<MapStation>> _nearbySearchNew({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    final uri = Uri.parse('https://places.googleapis.com/v1/places:searchNearby');
    final requestBody = jsonEncode({
      'includedTypes': ['electric_vehicle_charging_station'],
      'maxResultCount': MapsConfig.nearbySearchMaxResults,
      'locationRestriction': {
        'circle': {
          'center': {'latitude': latitude, 'longitude': longitude},
          'radius': radiusMeters.toDouble(),
        },
      },
    });

    final response = await _postJson(
      uri,
      body: requestBody,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': MapsConfig.placesApiKey,
        'X-Goog-FieldMask':
            'places.id,places.displayName,places.location,'
            'places.formattedAddress,places.evChargeOptions',
      },
      context: 'nearbySearchNew',
    );
    if (response == null) return [];

    final places = response['places'] as List<dynamic>? ?? [];
    final stations = <MapStation>[];
    for (final raw in places) {
      if (raw is! Map<String, dynamic>) continue;
      final station = _parsePlaceNew(raw, latitude, longitude);
      if (station != null) stations.add(station);
    }
    return stations;
  }

  MapStation? _parsePlaceNew(
    Map<String, dynamic> place,
    double userLat,
    double userLng,
  ) {
    final id = place['id'] as String?;
    final displayName = place['displayName'] as Map<String, dynamic>?;
    final name = displayName?['text'] as String?;
    final location = place['location'] as Map<String, dynamic>?;
    final lat = (location?['latitude'] as num?)?.toDouble();
    final lng = (location?['longitude'] as num?)?.toDouble();
    if (id == null || name == null || lat == null || lng == null) return null;

    final address = place['formattedAddress'] as String? ?? name;
    final evOptions = place['evChargeOptions'] as Map<String, dynamic>?;
    final connectorCount = (evOptions?['connectorCount'] as num?)?.toInt();
    final aggregation =
        evOptions?['connectorAggregation'] as List<dynamic>? ?? [];
    double? maxChargeRateKw;
    final connectorTypes = <String>[];
    for (final agg in aggregation) {
      if (agg is! Map<String, dynamic>) continue;
      final rate = (agg['maxChargeRateKw'] as num?)?.toDouble();
      if (rate != null &&
          (maxChargeRateKw == null || rate > maxChargeRateKw)) {
        maxChargeRateKw = rate;
      }
      final type = agg['type'] as String?;
      if (type != null && type.isNotEmpty) connectorTypes.add(type);
    }

    final chargerHint = connectorCount != null
        ? '$connectorCount connector${connectorCount == 1 ? '' : 's'}'
            '${maxChargeRateKw != null ? ' · ${maxChargeRateKw.toStringAsFixed(0)} kW' : ''}'
        : 'EV charging';

    final km = GeoUtils.distanceKm(userLat, userLng, lat, lng);

    return MapStation.external(
      id: id,
      name: name,
      address: address,
      latitude: lat,
      longitude: lng,
      distanceKm: km,
      external: ExternalPlaceMetadata(
        placeId: id,
        chargerTypeHint: chargerHint,
        connectorCount: connectorCount,
        maxChargeRateKw: maxChargeRateKw,
        connectorTypes: connectorTypes.isEmpty ? null : connectorTypes,
      ),
    );
  }

  Future<Map<String, dynamic>?> _postJson(
    Uri uri, {
    required String body,
    required Map<String, String> headers,
    required String context,
  }) async {
    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 18));
      if (response.statusCode != 200) {
        MapPipelineLogger.places(
          '$context HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on Object catch (e) {
      MapPipelineLogger.places('$context failed: $e');
      return null;
    }
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

}
