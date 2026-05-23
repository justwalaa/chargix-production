import '../models/map_station.dart';
import '../models/map_station_item.dart';
import 'geo_utils.dart';

enum MapStationFilter {
  all,
  partners,
  external,
  available,
}

/// Sort, filter, merge, and dedupe unified map stations.
abstract final class MapStationUtils {
  static const double _dedupeRadiusKm = 0.05;

  static List<MapStationItem> withDistances({
    required List<MapStation> stations,
    double? userLat,
    double? userLng,
  }) {
    return stations.map((station) {
      double? km = station.distanceKm;
      if (km == null && userLat != null && userLng != null) {
        km = GeoUtils.distanceKm(
          userLat,
          userLng,
          station.latitude,
          station.longitude,
        );
      }
      return MapStationItem(
        station: station.copyWith(distanceKm: km),
        distanceKm: km,
      );
    }).toList();
  }

  static List<MapStationItem> sortByDistance(List<MapStationItem> items) {
    final copy = List<MapStationItem>.from(items);
    copy.sort((a, b) {
      final ad = a.distanceKm;
      final bd = b.distanceKm;
      if (ad == null && bd == null) {
        return 0;
      }
      if (ad == null) {
        return 1;
      }
      if (bd == null) {
        return -1;
      }
      return ad.compareTo(bd);
    });
    return copy;
  }

  static List<MapStation> mergePartnerAndExternal({
    required List<MapStation> partners,
    required List<MapStation> external,
  }) {
    final merged = List<MapStation>.from(partners);
    for (final ext in external) {
      final duplicate = partners.any(
        (p) =>
            GeoUtils.distanceKm(
              p.latitude,
              p.longitude,
              ext.latitude,
              ext.longitude,
            ) <
            _dedupeRadiusKm,
      );
      if (!duplicate) {
        merged.add(ext);
      }
    }
    return merged;
  }

  static List<MapStationItem> applyFilter(
    List<MapStationItem> items,
    MapStationFilter filter,
  ) {
    switch (filter) {
      case MapStationFilter.all:
        return items;
      case MapStationFilter.partners:
        return items.where((e) => e.station.isPartner).toList(growable: false);
      case MapStationFilter.external:
        return items.where((e) => e.station.isExternal).toList(growable: false);
      case MapStationFilter.available:
        return items
            .where(
              (e) =>
                  e.station.isPartner &&
                  (e.station.partner?.station.availablePorts ?? 0) > 0,
            )
            .toList(growable: false);
    }
  }

  static List<MapStationItem> applySearch(
    List<MapStationItem> items,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return items;
    }
    return items
        .where((e) {
          final s = e.station;
          return s.name.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q);
        })
        .toList(growable: false);
  }
}
