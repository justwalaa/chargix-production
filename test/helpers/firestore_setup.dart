import 'package:chargix_production/core/firebase/firestore_paths.dart';
import 'package:chargix_production/data/firestore/bookings_firestore_service.dart';
import 'package:chargix_production/data/firestore/favorites_firestore_service.dart';
import 'package:chargix_production/data/firestore/users_firestore_service.dart';
import 'package:chargix_production/models/booking_model.dart';
import 'package:chargix_production/models/favorite_station_model.dart';
import 'package:chargix_production/models/station_model.dart';
import 'package:chargix_production/models/user_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

/// Seeds [FakeFirebaseFirestore] with common documents for repository tests.
abstract final class FirestoreTestSetup {
  static FakeFirebaseFirestore fresh() => FakeFirebaseFirestore();

  static Future<void> seedUser(
    FakeFirebaseFirestore db,
    UserModel user,
  ) async {
    await db
        .collection(FirestorePaths.users)
        .doc(user.uid)
        .set(user.toMap());
  }

  static Future<void> seedStation(
    FakeFirebaseFirestore db,
    StationModel station,
  ) async {
    await db
        .collection(FirestorePaths.stations)
        .doc(station.id)
        .set(station.toMap());
  }

  static Future<void> seedBooking(
    FakeFirebaseFirestore db,
    BookingModel booking,
  ) async {
    await db
        .collection(FirestorePaths.bookings)
        .doc(booking.id)
        .set(booking.toMap());
  }

  static Future<void> seedFavorite(
    FakeFirebaseFirestore db,
    FavoriteStationModel favorite,
  ) async {
    await db
        .collection(FirestorePaths.favorites)
        .doc(favorite.id)
        .set(favorite.toMap());
  }

  static UsersFirestoreService usersService(FakeFirebaseFirestore db) =>
      UsersFirestoreService(firestore: db);

  static BookingsFirestoreService bookingsService(FakeFirebaseFirestore db) =>
      BookingsFirestoreService(firestore: db);

  static FavoritesFirestoreService favoritesService(FakeFirebaseFirestore db) =>
      FavoritesFirestoreService(firestore: db);
}
