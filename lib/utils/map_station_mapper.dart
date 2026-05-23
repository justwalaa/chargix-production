import '../models/map_station.dart';
import '../models/partner_map_data.dart';
import '../models/station_model.dart';
import 'geo_utils.dart';

/// Converts Firestore partner models into unified [MapStation] entities.
abstract final class MapStationMapper {
  static MapStation fromPartner(
    StationModel model, {
    double? userLat,
    double? userLng,
  }) {
    double? km;
    if (userLat != null && userLng != null) {
      km = GeoUtils.distanceKm(
        userLat,
        userLng,
        model.latitude,
        model.longitude,
      );
    }
    return MapStation.partner(
      id: model.id,
      name: model.name,
      address: model.address,
      latitude: model.latitude,
      longitude: model.longitude,
      distanceKm: km,
      partner: PartnerMapData(station: model),
    );
  }

  static List<MapStation> fromPartners(
    List<StationModel> models, {
    double? userLat,
    double? userLng,
  }) {
    return models
        .map((m) => fromPartner(m, userLat: userLat, userLng: userLng))
        .toList(growable: false);
  }
}
