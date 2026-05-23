import 'repositories/booking_repository.dart';
import 'repositories/charging_session_repository.dart';
import 'repositories/favorites_repository.dart';
import 'repositories/station_owner_repository.dart';
import 'repositories/station_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/vehicle_repository.dart';
import '../services/google_places_service.dart';
import 'seed/firestore_seed_service.dart';

/// App-wide access point for Firestore repositories and seed runner.
abstract final class ChargixData {
  static UserRepository get users => UserRepository.instance;
  static VehicleRepository get vehicles => VehicleRepository.instance;
  static StationRepository get stations => StationRepository.instance;
  static StationOwnerRepository get stationOwner =>
      StationOwnerRepository.instance;
  static BookingRepository get bookings => BookingRepository.instance;
  static FavoritesRepository get favorites => FavoritesRepository.instance;
  static ChargingSessionRepository get chargingSessions =>
      ChargingSessionRepository.instance;
  static FirestoreSeedService get seed => FirestoreSeedService.instance;
  static GooglePlacesService get places => GooglePlacesService.instance;
}
