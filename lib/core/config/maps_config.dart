/// Google Maps / Places API key (same GCP project as Android Maps SDK).
///
/// Enable **Places API** in Google Cloud Console for nearby charger search.
abstract final class MapsConfig {
  static const String placesApiKey = 'AIzaSyC2xi5scAYDmxO5Vask7PvGt-lbx9VE81Y';

  static const int nearbySearchRadiusMeters = 8000;
  static const String nearbySearchType = 'electric_vehicle_charging_station';
}
