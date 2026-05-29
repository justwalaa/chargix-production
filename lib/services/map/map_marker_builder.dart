import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/map_station.dart';
import 'map_pipeline_logger.dart';

/// Builds Google Maps markers from unified [MapStation] entities.
abstract final class MapMarkerBuilder {
  static Set<Marker> build({
    required List<MapStation> stations,
    required BitmapDescriptor partnerIcon,
    required BitmapDescriptor externalIcon,
    required void Function(MapStation station) onMarkerTap,
  }) {
    final markers = <Marker>{};
    var skipped = 0;

    for (final station in stations) {
      if (station.latitude == 0 && station.longitude == 0) {
        skipped++;
        continue;
      }
      markers.add(
        Marker(
          markerId: MarkerId(station.markerId),
          position: LatLng(station.latitude, station.longitude),
          icon: station.isPartner ? partnerIcon : externalIcon,
          infoWindow: InfoWindow(
            title: station.name,
            snippet: station.isPartner ? 'Chargix partner' : 'Public charger',
          ),
          onTap: () => onMarkerTap(station),
        ),
      );
    }

    MapPipelineLogger.markerBuilder(
      'built=${markers.length} skippedInvalid=$skipped '
      'input=${stations.length}',
    );
    return markers;
  }
}
