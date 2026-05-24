// lib/services/map/stations_map_service.dart
//
// Single service that provides ALL visible stations for the map:
//   • Chargix partner stations (green)  — from Firestore
//   • External/public EV stations (blue) — from Google Places
//
// Both lists are validated (no ocean/null coords), deduplicated by proximity,
// distance-sorted, and returned as a unified List<MapStation>.

import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/map_station_model.dart';
import 'places_service.dart';

class StationsMapService {
  StationsMapService._();
  static final StationsMapService instance = StationsMapService._();

  final _firestore = FirebaseFirestore.instance;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns all visible stations around [center] within [radiusMeters].
  ///
  /// - Partner stations fetched from Firestore (no radius limit — all approved)
  /// - External stations fetched from Places API
  /// - Both validated, deduplicated (proximity 50m), distance-sorted
  Future<StationsMapResult> fetchAllStations({
    required LatLng center,
    double radiusMeters = 8000,
  }) async {
    dev.log('[StationsMap] Fetching around '
        '${center.latitude.toStringAsFixed(4)}, '
        '${center.longitude.toStringAsFixed(4)} '
        'r=${radiusMeters.round()}m',
        name: 'StationsMapService');

    // Run both fetches concurrently
    final results = await Future.wait([
      _fetchChargixStations(center),
      PlacesService.instance.fetchNearbyEVStations(
        center:       center,
        radiusMeters: radiusMeters,
      ),
    ]);

    final chargixStations  = results[0] as List<MapStation>;
    final externalStations = results[1] as List<MapStation>;

    dev.log('[StationsMap] Chargix: ${chargixStations.length}, '
        'External: ${externalStations.length}',
        name: 'StationsMapService');

    // Deduplicate: remove external stations that are within 50m of a Chargix
    // station (they're the same physical location, prefer the Chargix entry).
    final deduped = _deduplicateExternal(chargixStations, externalStations);

    dev.log('[StationsMap] After dedup: ${deduped.length} external kept',
        name: 'StationsMapService');

    // Compute distances and sort
    final all = [
      ...chargixStations,
      ...deduped,
    ];

    final withDistance = all
        .map((s) => s.withDistance(
      CoordValidator.haversineKm(center, s.position),
    ))
        .toList()
      ..sort((a, b) =>
          (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));

    dev.log('[StationsMap] Total stations returned: ${withDistance.length}',
        name: 'StationsMapService');

    return StationsMapResult(
      all:      withDistance,
      chargix:  withDistance.where((s) => s.isChargix).toList(),
      external: withDistance.where((s) => s.isExternal).toList(),
    );
  }

  // ── Firestore: partner stations ────────────────────────────────────────────

  Future<List<MapStation>> _fetchChargixStations(LatLng center) async {
    try {
      // Fetch all approved/active Chargix stations
      // Status values: 'approved', 'active', 'publicOnMap', 'public_on_map'
      final snapshot = await _firestore
          .collection('stations')
          .where('status', whereIn: [
        'approved',
        'active',
        'publicOnMap',
        'public_on_map',
        'available',
      ])
          .get();

      dev.log('[StationsMap] Firestore returned ${snapshot.docs.length} stations',
          name: 'StationsMapService');

      final valid = <MapStation>[];
      int skipped = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lat  = (data['lat'] as num?)?.toDouble() ?? 0.0;
        final lng  = (data['lng'] as num?)?.toDouble() ?? 0.0;

        if (!CoordValidator.isValidMENA(lat, lng)) {
          dev.log('[StationsMap] Skipped invalid coord for ${doc.id}: '
              '$lat,$lng', name: 'StationsMapService');
          skipped++;
          continue;
        }

        valid.add(MapStation.fromFirestore(doc.id, data));
      }

      if (skipped > 0) {
        dev.log('[StationsMap] Skipped $skipped stations with invalid coords',
            name: 'StationsMapService');
      }

      return valid;
    } catch (e) {
      dev.log('[StationsMap] Firestore error: $e', name: 'StationsMapService');
      return [];
    }
  }

  // ── Deduplication ──────────────────────────────────────────────────────────

  List<MapStation> _deduplicateExternal(
      List<MapStation> chargix,
      List<MapStation> external,
      ) {
    const proximityThresholdKm = 0.05; // 50 metres

    return external.where((ext) {
      for (final c in chargix) {
        final dist = CoordValidator.haversineKm(c.position, ext.position);
        if (dist < proximityThresholdKm) {
          dev.log('[StationsMap] Dedup: external "${ext.name}" '
              'too close to chargix "${c.name}" (${(dist * 1000).round()}m)',
              name: 'StationsMapService');
          return false; // remove this external entry
        }
      }
      return true; // keep it
    }).toList();
  }

  // ── Search / filter ────────────────────────────────────────────────────────

  /// Filter a pre-loaded station list by query string.
  /// Matches station name, address, city, connector type.
  List<MapStation> search(List<MapStation> stations, String query) {
    if (query.trim().isEmpty) return stations;
    final q = query.toLowerCase().trim();
    return stations.where((s) {
      if (s.name.toLowerCase().contains(q))    return true;
      if (s.address?.toLowerCase().contains(q) ?? false) return true;
      if (s.connectorTypes.any((c) => c.toLowerCase().contains(q))) return true;
      // EV keyword hits
      final evKeywords = ['ev', 'electric', 'charge', 'charger', 'charging',
        'كهربائي', 'شحن'];
      if (evKeywords.any((k) => q.contains(k))) return true;
      return false;
    }).toList();
  }
}

// ── Result ─────────────────────────────────────────────────────────────────

class StationsMapResult {
  final List<MapStation> all;
  final List<MapStation> chargix;
  final List<MapStation> external;

  const StationsMapResult({
    required this.all,
    required this.chargix,
    required this.external,
  });

  bool get isEmpty => all.isEmpty;
}