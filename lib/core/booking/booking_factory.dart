import 'package:chargix_production/models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../models/station_model.dart';

/// Creates pending bookings for drivers (Firestore-ready).
abstract final class BookingFactory {
  static BookingModel pendingForStation({
    required String userId,
    required StationModel station,
    String? vehicleId,
    int? portNumber,
  }) {
    final now = DateTime.now();
    final start = now.add(const Duration(minutes: 30));
    final end = start.add(const Duration(hours: 1));
    const estKwh = 35.0;
    return BookingModel(
      id: 'bk_${userId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      stationId: station.id,
      vehicleId: vehicleId,
      status: BookingStatus.pending,
      scheduledStart: start,
      scheduledEnd: end,
      portNumber: portNumber ?? 1,
      priceTotal: station.pricePerKwh * estKwh,
      notes: 'Requested via Chargix app',
      createdAt: now,
      updatedAt: now,
    );
  }
}
