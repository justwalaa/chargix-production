/// Central Firestore collection and document path constants (admin-dashboard friendly).
abstract final class FirestorePaths {
  static const String users = 'users';
  static const String vehicles = 'vehicles';
  static const String stations = 'stations';
  static const String bookings = 'bookings';
  static const String chargingSessions = 'charging_sessions';
  static const String favorites = 'favorites';
  static const String stationOwnerProfiles = 'station_owner_profiles';
  static const String notifications = 'notifications';

  /// App metadata (seed flags, feature toggles).
  static const String meta = 'meta';
  static const String metaSeedDoc = 'seed';

  static String user(String uid) => '$users/$uid';
  static String vehicle(String id) => '$vehicles/$id';
  static String station(String id) => '$stations/$id';
  static String booking(String id) => '$bookings/$id';
  static String chargingSession(String id) => '$chargingSessions/$id';

  static String stationSlotsCollection(String stationId) =>
      '$stations/$stationId/slots';

  static String stationSlot(String stationId, String slotId) =>
      '${stationSlotsCollection(stationId)}/$slotId';

  static String favorite(String userId, String stationId) =>
      '$favorites/${userId}_$stationId';

  static String stationOwnerProfile(String uid) =>
      '$stationOwnerProfiles/$uid';

  static String notification(String id) => '$notifications/$id';

  static String userNotificationsCollection(String uid) =>
      '$users/$uid/notifications';

  static String userNotification(String uid, String notifId) =>
      '${userNotificationsCollection(uid)}/$notifId';
}
