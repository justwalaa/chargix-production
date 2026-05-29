import 'package:chargix_production/models/booking_model.dart';
import 'package:chargix_production/models/enums/booking_status.dart';
import 'package:chargix_production/models/enums/station_status.dart';
import 'package:chargix_production/models/enums/user_role.dart';
import 'package:chargix_production/models/external_place_metadata.dart';
import 'package:chargix_production/models/favorite_station_model.dart';
import 'package:chargix_production/models/map_station.dart';
import 'package:chargix_production/models/partner_map_data.dart';
import 'package:chargix_production/models/station_model.dart';
import 'package:chargix_production/models/station_slot_model.dart';
import 'package:chargix_production/models/user_model.dart';
import 'package:chargix_production/models/vehicle_model.dart';

/// Centralized test fixtures aligned with production model shapes.
abstract final class FakeData {
  static const ammanLat = 31.9454;
  static const ammanLng = 35.9284;
  static const aqabaLat = 29.5321;
  static const aqabaLng = 35.0063;

  static StationModel station({
    String id = 'station-1',
    String name = 'Chargix Amman Hub',
    String address = 'King Hussein St, Amman',
    double latitude = ammanLat,
    double longitude = ammanLng,
    int availablePorts = 2,
    int totalPorts = 4,
    double pricePerKwh = 0.35,
    double rating = 4.5,
    StationStatus status = StationStatus.active,
    String? ownerUserId = 'owner-1',
    String? city = 'Amman',
    bool shipmentBookingEnabled = true,
    String? description,
  }) {
    return StationModel(
      id: id,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      availablePorts: availablePorts,
      totalPorts: totalPorts,
      pricePerKwh: pricePerKwh,
      rating: rating,
      status: status,
      ownerUserId: ownerUserId,
      city: city,
      shipmentBookingEnabled: shipmentBookingEnabled,
      description: description,
    );
  }

  static StationSlotModel slot({
    String id = 'slot-1',
    String stationId = 'station-1',
    String label = 'Bay A',
    bool isOpen = true,
    bool isAvailable = true,
    double powerKw = 22,
  }) {
    return StationSlotModel(
      id: id,
      stationId: stationId,
      label: label,
      isOpen: isOpen,
      isAvailable: isAvailable,
      powerKw: powerKw,
    );
  }

  static BookingModel booking({
    String id = 'booking-1',
    String userId = 'user-1',
    String stationId = 'station-1',
    BookingStatus status = BookingStatus.pending,
    String? slotId = 'slot-1',
    int? portNumber = 1,
    double? priceTotal = 12.5,
    DateTime? createdAt,
  }) {
    return BookingModel(
      id: id,
      userId: userId,
      stationId: stationId,
      status: status,
      slotId: slotId,
      portNumber: portNumber,
      priceTotal: priceTotal,
      scheduledStart: DateTime.utc(2026, 5, 30, 10),
      scheduledEnd: DateTime.utc(2026, 5, 30, 11),
      createdAt: createdAt ?? DateTime.utc(2026, 5, 30, 9),
    );
  }

  static UserModel user({
    String uid = 'user-1',
    String phoneE164 = '+962791234567',
    UserRole role = UserRole.user,
    String? stationId,
  }) {
    return UserModel(
      uid: uid,
      phoneE164: phoneE164,
      role: role,
      stationId: stationId,
    );
  }

  static VehicleModel vehicle({
    String id = 'vehicle-1',
    String userId = 'user-1',
    String make = 'Tesla',
    String model = 'Model 3',
    int? year = 2024,
  }) {
    return VehicleModel(
      id: id,
      userId: userId,
      make: make,
      model: model,
      year: year,
    );
  }

  static FavoriteStationModel favorite({
    String userId = 'user-1',
    String stationId = 'station-1',
  }) {
    return FavoriteStationModel(
      id: '${userId}_$stationId',
      userId: userId,
      stationId: stationId,
      createdAt: DateTime.utc(2026, 5, 30),
    );
  }

  static MapStation partnerMapStation({
    StationModel? stationModel,
    double? distanceKm,
  }) {
    final model = stationModel ?? FakeData.station();
    return MapStation.partner(
      id: model.id,
      name: model.name,
      address: model.address,
      latitude: model.latitude,
      longitude: model.longitude,
      distanceKm: distanceKm,
      partner: PartnerMapData(station: model),
    );
  }

  static MapStation externalMapStation({
    String id = 'ext-1',
    String name = 'Shell Recharge',
    String address = 'Desert Highway, Jordan',
    double latitude = aqabaLat,
    double longitude = aqabaLng,
    String placeId = 'place-abc',
    String? chargerTypeHint,
  }) {
    return MapStation.external(
      id: id,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      external: ExternalPlaceMetadata(
        placeId: placeId,
        chargerTypeHint: chargerTypeHint,
        rating: 4.2,
      ),
    );
  }
}
