/// Google Maps / Places configuration.
///
/// TWO separate keys are in use:
///   - Maps SDK display key: set in android/app/src/main/AndroidManifest.xml
///     (com.google.android.geo.API_KEY). Restricted to "Android apps".
///   - Places HTTP key (below): used for all Places API REST calls from Dart.
///     Restricted to "Places API" only — no Android-app restriction so plain
///     HTTP calls from the http package are accepted.
abstract final class MapsConfig {
  /// Key for all Google Places REST API calls (nearbysearch, textsearch,
  /// autocomplete, geocode). Distinct from the Maps SDK display key.
  static const String placesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_HTTP_KEY',
    defaultValue: 'AIzaSyDdHk6xeWjblZm-cQZFd89ysjmxSOBpqPk',
  );

  /// Amman, Jordan — map fallback when GPS unavailable.
  static const double fallbackLatitude = 31.9539;
  static const double fallbackLongitude = 35.9106;

  static const int nearbySearchRadiusMeters = 25000;
  static const int nearbySearchMaxResults = 20;

  static const Duration placesAutocompleteDebounce = Duration(milliseconds: 350);
}
