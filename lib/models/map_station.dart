import 'partner_map_data.dart';
import 'external_place_metadata.dart';

enum MapStationSourceType {
  partnerFirestore,
  externalGooglePlaces,
}

class MapStation {
  const MapStation.partner({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    required this.partner,
  })  : sourceType = MapStationSourceType.partnerFirestore,
        external = null;

  const MapStation.external({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    required this.external,
  })  : sourceType = MapStationSourceType.externalGooglePlaces,
        partner = null;

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? distanceKm;

  final MapStationSourceType sourceType;

  final PartnerMapData? partner;
  final ExternalPlaceMetadata? external;

  bool get isPartner => partner != null;
  bool get isChargix => isPartner;
  bool get isExternal => external != null;

  bool get isBookable => partner?.canBook ?? false;

  /// Unique marker id for Google Maps (avoids partner/external collisions).
  String get markerId =>
      isPartner ? 'partner_$id' : 'ext_${external?.placeId ?? id}';

  MapStation copyWith({
    double? distanceKm,
  }) {
    if (isPartner) {
      return MapStation.partner(
        id: id,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        distanceKm: distanceKm ?? this.distanceKm,
        partner: partner!,
      );
    }

    return MapStation.external(
      id: id,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      distanceKm: distanceKm ?? this.distanceKm,
      external: external!,
    );
  }
}