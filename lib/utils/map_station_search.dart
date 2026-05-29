import '../models/map_station.dart';

/// Client-side search across merged map stations (Firestore + Places).
abstract final class MapStationSearch {
  static List<MapStation> filter(List<MapStation> stations, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return stations;

    return stations.where((s) => _matches(s, q)).toList(growable: false);
  }

  static bool _matches(MapStation station, String q) {
    if (station.name.toLowerCase().contains(q)) return true;
    if (station.address.toLowerCase().contains(q)) return true;

    final city = station.partner?.station.city?.toLowerCase();
    if (city != null && city.contains(q)) return true;

    final description = station.partner?.station.description?.toLowerCase();
    if (description != null && description.contains(q)) return true;

    final hint = station.external?.chargerTypeHint?.toLowerCase();
    if (hint != null && hint.contains(q)) return true;

    // Match individual address tokens (street, area).
    final tokens = station.address.toLowerCase().split(RegExp(r'[,\s]+'));
    for (final token in tokens) {
      if (token.length >= 3 && token.contains(q)) return true;
    }

    return false;
  }
}
