import '../../core/result/data_state.dart';
import 'package:chargix_production/models/booking_model.dart';
import '../../models/station_model.dart';
import '../../models/enums/booking_status.dart';
import '../firestore/booking_transaction_service.dart';
import '../firestore/bookings_firestore_service.dart';
import '../../models/station_slot_model.dart';
import 'station_owner_repository.dart';

class BookingRepository {
  BookingRepository({
    BookingsFirestoreService? service,
    BookingTransactionService? transactions,
  })  : _service = service ?? BookingsFirestoreService(),
        _transactions = transactions ?? BookingTransactionService.instance;

  static final BookingRepository instance = BookingRepository();

  final BookingsFirestoreService _service;
  final BookingTransactionService _transactions;

  Stream<List<BookingModel>> watchBookingsForUser(String userId) =>
      _service.watchBookingsForUser(userId);

  Stream<List<BookingModel>> watchBookingsForStation(String stationId) =>
      _service.watchBookingsForStation(stationId);

  Future<DataState<void>> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
    String? rejectionReason,
  }) async {
    try {
      await _service.updateBookingStatus(
        bookingId,
        status.value,
        rejectionReason: rejectionReason,
      );
      return const DataSuccess(null);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  Future<DataState<List<BookingModel>>> fetchBookingsForUser(String userId) async {
    try {
      final list = await _service.getBookingsForUser(userId);
      return DataSuccess(list);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  /// Atomic slot reservation via time-window booking path.
  Future<DataState<BookingModel>> reserveSlot({
    required String userId,
    required StationModel station,
    required StationSlotModel slot,
    required String windowId,
    required String dateKey,
    String? vehicleId,
  }) async {
    final result = await _transactions.reserveSlot(
      userId: userId,
      station: station,
      slot: slot,
      windowId: windowId,
      dateKey: dateKey,
      vehicleId: vehicleId,
    );
    if (result is DataSuccess<BookingModel>) {
      await StationOwnerRepository.instance.syncPortCountsFromSlots(station.id);
    }
    return result;
  }

  Future<DataState<void>> respondToBookingAtomic({
    required BookingModel booking,
    required BookingStatus status,
    String? rejectionReason,
  }) async {
    final result = await _transactions.respondToBooking(
      booking: booking,
      newStatus: status,
      rejectionReason: rejectionReason,
    );
    if (result is DataSuccess<void>) {
      await StationOwnerRepository.instance.syncPortCountsFromSlots(
        booking.stationId,
      );
    }
    return result;
  }

  Future<DataState<void>> saveBooking(BookingModel booking) async {
    try {
      final existing = await _service.getBooking(booking.id);
      await _service.upsertBooking(
        booking,
        isCreate: existing == null,
      );
      return const DataSuccess(null);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }
}
