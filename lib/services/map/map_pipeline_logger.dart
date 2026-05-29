import 'package:flutter/foundation.dart';

/// Structured debug logging for the EV map station pipeline.
abstract final class MapPipelineLogger {
  static void pipeline(String message) => _log('MapPipeline', message);

  static void firestore(String message) => _log('FirestoreStations', message);

  static void places(String message) => _log('PlacesStations', message);

  static void markerBuilder(String message) => _log('MarkerBuilder', message);

  static void mapRender(String message) => _log('MapRender', message);

  static void _log(String tag, String message) {
    debugPrint('[$tag] $message');
  }
}
