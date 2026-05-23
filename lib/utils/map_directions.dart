import 'package:url_launcher/url_launcher.dart';

import '../models/map_station.dart';

/// Opens external navigation (Google Maps) for any map station.
abstract final class MapDirections {
  static Uri mapsUri(MapStation station) {
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${station.latitude},${station.longitude}'
      '&destination_place_id=${station.external?.placeId ?? ''}',
    );
  }

  static Future<void> open(MapStation station) async {
    final uri = mapsUri(station);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      final fallback = Uri.parse(
        'geo:${station.latitude},${station.longitude}?q=${station.latitude},${station.longitude}(${Uri.encodeComponent(station.name)})',
      );
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }
}
