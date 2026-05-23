/// App roles: driver, station operator, platform admin.
enum UserRole {
  user('user'),
  station('station'),
  stationOwner('station_owner'),
  admin('admin');

  const UserRole(this.value);
  final String value;

  bool get isStation =>
      this == UserRole.station || this == UserRole.stationOwner;
  bool get isDriver => this == UserRole.user;

  static UserRole fromValue(String? raw) {
    if (raw == 'station_owner') {
      return UserRole.stationOwner;
    }
    return UserRole.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => UserRole.user,
    );
  }
}
