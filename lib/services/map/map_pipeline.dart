import '../../models/map_station.dart';
import '../../models/station_model.dart';
import '../../utils/geo_utils.dart';
import '../../utils/map_station_mapper.dart';
import 'map_pipeline_logger.dart';

/// Result of parsing, validating, and merging Firestore + Places stations.
class MapPipelineResult {
  const MapPipelineResult({
    required this.stations,
    required this.firestoreTotal,
    required this.firestoreAccepted,
    required this.firestoreRejectedCoords,
    required this.placesTotal,
    required this.placesAccepted,
    required this.placesRejectedCoords,
    required this.dedupedExternalCount,
    required this.mergedCount,
  });

  final List<MapStation> stations;
  final int firestoreTotal;
  final int firestoreAccepted;
  final int firestoreRejectedCoords;
  final int placesTotal;
  final int placesAccepted;
  final int placesRejectedCoords;
  final int dedupedExternalCount;
  final int mergedCount;
}

/// Firestore → validation → merge with Places → sorted list for the map.
abstract final class MapPipeline {
  static const _dedupeKm = 0.05;

  static MapPipelineResult process({
    required List<StationModel> rawFirestore,
    required List<MapStation> rawPlaces,
    required double centerLat,
    required double centerLng,
  }) {
    MapPipelineLogger.pipeline(
      'start merge center=($centerLat, $centerLng)',
    );
    MapPipelineLogger.firestore('raw documents=${rawFirestore.length}');

    var firestoreRejected = 0;
    final validPartners = <StationModel>[];
    for (final station in rawFirestore) {
      if (!_isValidCoord(station.latitude, station.longitude)) {
        firestoreRejected++;
        MapPipelineLogger.firestore(
          'rejected invalid coords id=${station.id} '
          'lat=${station.latitude} lng=${station.longitude}',
        );
        continue;
      }
      validPartners.add(station);
    }

    final partnerStations = MapStationMapper.fromPartners(
      validPartners,
      userLat: centerLat,
      userLng: centerLng,
    );
    MapPipelineLogger.firestore(
      'accepted=${partnerStations.length} rejectedCoords=$firestoreRejected',
    );

    MapPipelineLogger.places('raw results=${rawPlaces.length}');
    var placesRejected = 0;
    final validPlaces = <MapStation>[];
    for (final place in rawPlaces) {
      if (!_isValidCoord(place.latitude, place.longitude)) {
        placesRejected++;
        MapPipelineLogger.places(
          'rejected invalid coords id=${place.id}',
        );
        continue;
      }
      validPlaces.add(place);
    }
    MapPipelineLogger.places(
      'accepted=${validPlaces.length} rejectedCoords=$placesRejected',
    );

    final dedupedExternal = _dedupeExternal(partnerStations, validPlaces);
    final merged = <MapStation>[
      ...partnerStations,
      ...dedupedExternal,
    ]..sort(
        (a, b) => (a.distanceKm ?? double.infinity)
            .compareTo(b.distanceKm ?? double.infinity),
      );

    MapPipelineLogger.pipeline(
      'merged total=${merged.length} '
      'partner=${partnerStations.length} '
      'external=${dedupedExternal.length} '
      '(places before dedupe=${validPlaces.length})',
    );

    if (merged.isEmpty) {
      MapPipelineLogger.pipeline(
        'WARNING empty merge — firestore=${rawFirestore.length} '
        'places=${rawPlaces.length}',
      );
    }

    return MapPipelineResult(
      stations: merged,
      firestoreTotal: rawFirestore.length,
      firestoreAccepted: partnerStations.length,
      firestoreRejectedCoords: firestoreRejected,
      placesTotal: rawPlaces.length,
      placesAccepted: validPlaces.length,
      placesRejectedCoords: placesRejected,
      dedupedExternalCount: dedupedExternal.length,
      mergedCount: merged.length,
    );
  }

  static List<MapStation> _dedupeExternal(
    List<MapStation> partners,
    List<MapStation> external,
  ) {
    return external.where((ext) {
      for (final p in partners) {
        final distance = GeoUtils.distanceKm(
          p.latitude,
          p.longitude,
          ext.latitude,
          ext.longitude,
        );
        if (distance < _dedupeKm) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  static bool _isValidCoord(double lat, double lng) {
    if (lat == 0 && lng == 0) return false;
    if (lat.isNaN || lng.isNaN) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }
}
