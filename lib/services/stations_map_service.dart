import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/config/maps_config.dart';
import '../core/result/data_state.dart';
import '../data/chargix_data.dart';
import '../models/map_station.dart';
import '../models/station_model.dart';
import '../utils/geo_utils.dart';
import '../utils/map_station_search.dart';
import 'google_places_service.dart';
import 'map/map_pipeline.dart';
import 'map/map_pipeline_logger.dart';

/// Loads partner (Firestore) + external (Google Places) stations for the map.
class MapStationsService {
  MapStationsService._();

  static final MapStationsService instance = MapStationsService._();

  final _controller = StreamController<List<MapStation>>.broadcast();
  List<MapStation> _latest = const [];
  LatLng? _lastCenter;
  List<StationModel> _latestPartners = const [];
  List<MapStation> _cachedExternal = const [];
  bool _placesLoadedOnce = false;
  StreamSubscription<List<StationModel>>? _partnerSub;
  bool _loadingPlaces = false;
  int _loadGeneration = 0;

  Stream<List<MapStation>> get stationsStream async* {
    if (_latest.isNotEmpty) {
      yield _latest;
    }
    yield* _controller.stream;
  }

  /// Live Firestore partner updates merged with last Places fetch.
  void startPartnerWatch() {
    _partnerSub?.cancel();
    _partnerSub = ChargixData.stations.watchMapPartnerStations().listen(
      (partners) {
        MapPipelineLogger.firestore(
          'watch update partners=${partners.length}',
        );
        _latestPartners = partners;
        unawaited(_emitMerged(center: _lastCenter));
      },
      onError: (Object e, StackTrace st) {
        MapPipelineLogger.firestore('watch error: $e\n$st');
      },
    );
  }

  Future<void> load({
    required double latitude,
    required double longitude,
    double? radiusMeters,
  }) async {
    final generation = ++_loadGeneration;
    _lastCenter = LatLng(latitude, longitude);

    final radius = (radiusMeters ?? MapsConfig.nearbySearchRadiusMeters).round();
    MapPipelineLogger.pipeline(
      'load @ ($latitude, $longitude) r=${radius}m gen=$generation',
    );

    final partnersFuture = ChargixData.stations.fetchMapPartnerStations();
    final externalFuture =
        GooglePlacesService.instance.fetchNearbyChargingStations(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radius,
    );

    final partnersResult = await partnersFuture;
    if (generation != _loadGeneration) {
      MapPipelineLogger.pipeline('load gen=$generation superseded — skip');
      return;
    }

    final partners = partnersResult.dataOrNull ?? const [];
    if (partnersResult is DataError<List<StationModel>>) {
      MapPipelineLogger.firestore(
        'fetch error: ${partnersResult.errorOrNull}',
      );
    } else {
      _latestPartners = partners;
      MapPipelineLogger.firestore('fetch ok count=${partners.length}');
    }

    List<MapStation> external = const [];
    try {
      external = await externalFuture;
    } on Object catch (e, st) {
      MapPipelineLogger.places('fetch failed: $e\n$st');
    }

    if (generation != _loadGeneration) return;

    if (external.isNotEmpty) {
      _cachedExternal = external;
      _placesLoadedOnce = true;
    }

    await _mergeAndEmit(
      partners: _latestPartners,
      external: external.isNotEmpty ? external : _cachedExternal,
      centerLat: latitude,
      centerLng: longitude,
    );
  }

  Future<void> refreshExternalIfMoved({
    required double latitude,
    required double longitude,
    double minMoveKm = 0.8,
  }) async {
    final last = _lastCenter;
    if (last == null) {
      await load(latitude: latitude, longitude: longitude);
      return;
    }
    final moved = GeoUtils.distanceKm(
      last.latitude,
      last.longitude,
      latitude,
      longitude,
    );
    if (moved < minMoveKm) {
      MapPipelineLogger.pipeline(
        'camera moved ${moved.toStringAsFixed(2)}km — skip Places refresh',
      );
      return;
    }
    MapPipelineLogger.pipeline(
      'camera moved ${moved.toStringAsFixed(2)}km — refresh Places',
    );
    await _refreshPlacesOnly(latitude: latitude, longitude: longitude);
  }

  Future<void> _refreshPlacesOnly({
    required double latitude,
    required double longitude,
  }) async {
    if (_loadingPlaces) return;
    _loadingPlaces = true;
    _lastCenter = LatLng(latitude, longitude);
    final generation = ++_loadGeneration;

    List<MapStation> external = const [];
    try {
      external =
          await GooglePlacesService.instance.fetchNearbyChargingStations(
        latitude: latitude,
        longitude: longitude,
      );
    } on Object catch (e) {
      MapPipelineLogger.places('refresh failed: $e');
    } finally {
      _loadingPlaces = false;
    }

    if (generation != _loadGeneration) return;

    if (external.isNotEmpty) {
      _cachedExternal = external;
      _placesLoadedOnce = true;
    }

    await _mergeAndEmit(
      partners: _latestPartners,
      external: external.isNotEmpty ? external : _cachedExternal,
      centerLat: latitude,
      centerLng: longitude,
    );
  }

  Future<void> _emitMerged({LatLng? center}) async {
    final c = center ?? _lastCenter;
    if (c == null) return;
    if (!_placesLoadedOnce && _cachedExternal.isEmpty) {
      MapPipelineLogger.pipeline(
        'partner watch skipped — Places not loaded yet',
      );
      return;
    }
    await _mergeAndEmit(
      partners: _latestPartners,
      external: _cachedExternal,
      centerLat: c.latitude,
      centerLng: c.longitude,
    );
  }

  Future<void> _mergeAndEmit({
    required List<StationModel> partners,
    required List<MapStation> external,
    required double centerLat,
    required double centerLng,
  }) async {
    if (external.isNotEmpty) {
      _cachedExternal = external;
      _placesLoadedOnce = true;
    }

    final result = MapPipeline.process(
      rawFirestore: partners,
      rawPlaces: external,
      centerLat: centerLat,
      centerLng: centerLng,
    );

    _latest = result.stations;
    MapPipelineLogger.pipeline(
      'emit markers=${result.mergedCount} '
      'fs=${result.firestoreAccepted}/${result.firestoreTotal} '
      'places=${result.dedupedExternalCount}/${result.placesTotal}',
    );

    if (!_controller.isClosed) {
      _controller.add(_latest);
    }
  }

  List<MapStation> search(List<MapStation> stations, String query) {
    return MapStationSearch.filter(stations, query);
  }

  List<MapStation> get currentStations => List.unmodifiable(_latest);

  void dispose() {
    _partnerSub?.cancel();
    _controller.close();
  }
}
