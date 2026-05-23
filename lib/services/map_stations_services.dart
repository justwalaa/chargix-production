import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/repositories/station_repository.dart';
import '../models/map_station.dart';
import '../models/station_model.dart';
import '../utils/map_station_mapper.dart';
import 'google_places_service.dart';

/// Merges real-time Firestore partner stations with Google Places external
/// stations into a single [MapStation] list for the map layer.
///
/// Rules:
/// - External stations come from Google Places (real GPS + API key required).
/// - Partner stations come from Firestore in real-time via [StationRepository].
/// - If Places API fails → external list is empty (no fallback demo data).
/// - Partner stations always supersede an external station at the same location
///   (deduplication by proximity < 30 m).
class MapStationsService {
  MapStationsService({
    StationRepository? stationRepo,
    GooglePlacesService? placesService,
  })  : _stationRepo = stationRepo ?? StationRepository.instance,
        _placesService = placesService ?? GooglePlacesService.instance;

  static final MapStationsService instance = MapStationsService();

  final StationRepository _stationRepo;
  final GooglePlacesService _placesService;

  List<MapStation> _partnerStations = [];
  List<MapStation> _externalStations = [];
  StreamSubscription<List<StationModel>>? _partnerSub;

  final _controller = StreamController<List<MapStation>>.broadcast();

  /// Merged stream of all stations for the current search area.
  Stream<List<MapStation>> get stationsStream => _controller.stream;

  /// Call once when the map is ready and user location is known.
  /// Re-call when the camera moves significantly to refresh external results.
  Future<void> load({
    required double latitude,
    required double longitude,
  }) async {
    // 1. Subscribe to Firestore partner stations (real-time).
    _partnerSub?.cancel();
    _partnerSub = _stationRepo.watchMapPartnerStations().listen(
      (list) {
        _partnerStations =
            list.map((m) => MapStationMapper.fromPartner(m))
.toList(growable: false);
        _emit();
      },
      onError: (Object e) {
        debugPrint('MapStationsService: partner stream error — $e');
      },
    );

    // 2. Fetch external stations from Google Places (one-shot).
    await _refreshExternal(latitude: latitude, longitude: longitude);
  }

  Future<void> _refreshExternal({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final results = await _placesService.fetchNearbyChargingStations(
        latitude: latitude,
        longitude: longitude,
      );
      _externalStations = results;
    } on Object catch (e) {
      debugPrint('MapStationsService: external fetch error — $e');
      _externalStations = [];
    }
    _emit();
  }

  void _emit() {
    // Deduplicate: remove external stations that are within 30 m of a partner.
    final deduplicated = _externalStations.where((ext) {
      return !_partnerStations.any((p) {
        return _distanceMetres(
              ext.latitude,
              ext.longitude,
              p.latitude,
              p.longitude,
            ) <
            30;
      });
    }).toList();

    _controller.add([..._partnerStations, ...deduplicated]);
  }

  void dispose() {
    _partnerSub?.cancel();
    _controller.close();
  }

  // ── Haversine distance ─────────────────────────────────────────────────────

  static double _distanceMetres(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0; // Earth radius in metres
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  /// Formatted distance string between two lat/lng points.
  static String formatDistance(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    final m = _distanceMetres(fromLat, fromLng, toLat, toLng);
    if (m < 1000) return '${m.round()} m';
    final km = m / 1000;
    return '${km.toStringAsFixed(1)} km';
  }
}