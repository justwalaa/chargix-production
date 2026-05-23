import 'package:flutter/foundation.dart';

import 'map_station.dart';

/// [MapStation] with optional distance for list/map sorting.
@immutable
class MapStationItem {
  const MapStationItem({
    required this.station,
    this.distanceKm,
  });

  final MapStation station;
  final double? distanceKm;

  MapStationItem copyWith({double? distanceKm}) {
    return MapStationItem(
      station: station.copyWith(distanceKm: distanceKm ?? station.distanceKm),
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
