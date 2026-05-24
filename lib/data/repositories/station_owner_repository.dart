import 'package:flutter/foundation.dart';

import '../../core/result/data_state.dart';
import '../../services/station_places_verification_service.dart';
import 'package:chargix_production/models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../models/enums/station_status.dart';
import '../../models/operating_hours_model.dart';
import '../../models/station_model.dart';
import '../../models/station_registration_draft.dart';
import '../../models/station_slot_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../models/station_owner_profile_model.dart';
import '../firestore/booking_transaction_service.dart';
import '../firestore/bookings_firestore_service.dart';
import '../firestore/station_slots_firestore_service.dart';
import '../firestore/stations_firestore_service.dart';

/// Station-operator workflows: slots, pricing, bookings approval.
class StationOwnerRepository {
  StationOwnerRepository({
    StationsFirestoreService? stationsService,
    StationSlotsFirestoreService? slotsService,
    BookingsFirestoreService? bookingsService,
  })  : _stations = stationsService ?? StationsFirestoreService(),
        _slots = slotsService ?? StationSlotsFirestoreService(),
        _bookings = bookingsService ?? BookingsFirestoreService();

  static final StationOwnerRepository instance = StationOwnerRepository();

  final StationsFirestoreService _stations;
  final StationSlotsFirestoreService _slots;
  final BookingsFirestoreService _bookings;
  final BookingTransactionService _bookingTx =
      BookingTransactionService.instance;

  Future<DataState<StationModel>> getOwnedStation(String stationId) async {
    try {
      final station = await _stations.getStation(stationId);
      if (station == null) {
        return const DataError('Station not found.');
      }
      return DataSuccess(station);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  Stream<StationModel?> watchOwnedStation(String stationId) =>
      _stations.watchStation(stationId);

  Future<DataState<void>> upsertOwnedStation(StationModel station) async {
    try {
      final existing = await _stations.getStation(station.id);
      await _stations.upsertStation(station, isCreate: existing == null);
      return const DataSuccess(null);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  Stream<List<StationSlotModel>> watchSlots(String stationId) =>
      _slots.watchSlots(stationId);

  Future<DataState<void>> saveSlot(StationSlotModel slot) async {
    try {
      await _slots.upsertSlot(slot, isCreate: true);
      return const DataSuccess(null);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  Future<DataState<void>> updateStationPricing({
    required String stationId,
    required double pricePerKwh,
  }) async {
    try {
      final current = await _stations.getStation(stationId);
      if (current == null) {
        return const DataError('Station not found.');
      }
      await _stations.upsertStation(
        StationModel(
          id: current.id,
          name: current.name,
          address: current.address,
          latitude: current.latitude,
          longitude: current.longitude,
          availablePorts: current.availablePorts,
          totalPorts: current.totalPorts,
          pricePerKwh: pricePerKwh,
          rating: current.rating,
          status: current.status,
          amenities: current.amenities,
          imageUrl: current.imageUrl,
          operatorId: current.operatorId,
          ownerUserId: current.ownerUserId,
          description: current.description,
          operatingHours: current.operatingHours,
          shipmentBookingEnabled: current.shipmentBookingEnabled,
          isPublic: current.isPublic,
        ),
        isCreate: false,
      );
      return const DataSuccess(null);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  Stream<List<BookingModel>> watchStationBookings(String stationId) =>
      _bookings.watchBookingsForStation(stationId);

  Future<DataState<void>> respondToBooking({
    required BookingModel booking,
    required BookingStatus status,
    String? rejectionReason,
  }) async {
    return _bookingTx.respondToBooking(
      booking: booking,
      newStatus: status,
      rejectionReason: rejectionReason,
    );
  }

  /// Submits a new partner station for admin approval (`status: pending`).
  Future<DataState<String>> submitPartnerRegistration({
    required String ownerUserId,
    required StationRegistrationDraft draft,
  }) async {
    try {
      final stationId = ownerUserId;
      final verification =
          await StationPlacesVerificationService.instance.verifyAtCoordinates(
        stationName: draft.stationName,
        latitude: draft.latitude,
        longitude: draft.longitude,
        formattedAddress: draft.address,
      );
      final autoApproved = verification.isVerifiedOnGoogle;
      if (kDebugMode) {
        debugPrint(
          'Chargix onboarding: Places verify autoApproved=$autoApproved',
        );
      }

      final lat = verification.latitude ?? draft.latitude;
      final lng = verification.longitude ?? draft.longitude;

      final station = StationModel(
        id: stationId,
        name: draft.stationName,
        address: draft.address,
        latitude: lat,
        longitude: lng,
        availablePorts: autoApproved ? 1 : 0,
        totalPorts: 2,
        pricePerKwh: 0.42,
        rating: 0,
        status: autoApproved ? StationStatus.approved : StationStatus.pending,
        ownerUserId: ownerUserId,
        operatorId: ownerUserId,
        description: autoApproved
            ? 'Verified via Google Maps listing'
            : 'Awaiting Chargix approval',
        operatingHours: draft.operatingHours,
        isPublic: autoApproved,
        city: draft.city,
        contactEmail: draft.contactEmail,
        contactPhone: draft.contactPhone,
        managerName: draft.managerName,
        managerNationalId: draft.managerNationalId,
        backupContactPhone: draft.backupContactPhone,
        logoUrl: draft.logoUrl,
        imageUrl: draft.stationImageUrl,
      );
      final stationWithQr = StationModel(
        id: station.id,
        name: station.name,
        address: station.address,
        latitude: station.latitude,
        longitude: station.longitude,
        availablePorts: station.availablePorts,
        totalPorts: station.totalPorts,
        pricePerKwh: station.pricePerKwh,
        rating: station.rating,
        status: station.status,
        ownerUserId: station.ownerUserId,
        operatorId: station.operatorId,
        description: station.description,
        operatingHours: station.operatingHours,
        isPublic: station.isPublic,
        city: station.city,
        contactEmail: station.contactEmail,
        contactPhone: station.contactPhone,
        managerName: station.managerName,
        managerNationalId: station.managerNationalId,
        backupContactPhone: station.backupContactPhone,
        logoUrl: station.logoUrl,
        imageUrl: station.imageUrl,
        qrPayload: 'chargix://station/$stationId',
      );
      await _stations.upsertStation(stationWithQr, isCreate: true);
      await _slots.upsertSlot(
        StationSlotModel(
          id: '${stationId}_slot_1',
          stationId: stationId,
          label: 'Bay 1',
          pricePerKwh: 0.42,
        ),
        isCreate: true,
      );
      final profile = StationOwnerProfileModel(
        userId: ownerUserId,
        stationId: stationId,
        businessName: draft.stationName,
        supportPhone: draft.contactPhone,
      );
      await FirebaseFirestore.instance
          .doc(FirestorePaths.stationOwnerProfile(ownerUserId))
          .set(profile.toMap(), SetOptions(merge: true));
      return DataSuccess(stationId);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  /// Legacy bootstrap — prefer [submitPartnerRegistration].
  Future<DataState<String>> bootstrapStationForOwner({
    required String ownerUserId,
    required String stationName,
    required String address,
  }) async {
    return submitPartnerRegistration(
      ownerUserId: ownerUserId,
      draft: StationRegistrationDraft(
        stationName: stationName,
        contactEmail: 'owner@chargix.app',
        contactPhone: '',
        city: 'Amman',
        address: address,
        latitude: 31.9539,
        longitude: 35.9106,
        operatingHours: const OperatingHoursModel(),
        managerName: 'Station Manager',
      ),
    );
  }
}
