/// Google Maps / Places API key (must match Android/iOS Maps SDK key).
///
/// Enable **Places API** + **Maps SDK for Android** in Google Cloud Console.
abstract final class MapsConfig {
  /// Same key as `android/app/src/main/AndroidManifest.xml` → `com.google.android.geo.API_KEY`.
  static const String placesApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyAu_Fetxrs57m_ldC6axCrnBkUQXw9AC8M',
  );

  /// Amman, Jordan — map fallback when GPS unavailable.
  static const double fallbackLatitude = 31.9539;
  static const double fallbackLongitude = 35.9106;

  static const int nearbySearchRadiusMeters = 25000;
  static const String nearbySearchType = 'electric_vehicle_charging_station';

  /// Google requires ~2s before using [next_page_token].
  static const int maxPlacesPages = 3;

  static const Duration placesAutocompleteDebounce = Duration(milliseconds: 350);
}
