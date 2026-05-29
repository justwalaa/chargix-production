import 'package:chargix_production/models/enums/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole', () {
    test('fromValue maps station_owner alias', () {
      expect(UserRole.fromValue('station_owner'), UserRole.stationOwner);
    });

    test('fromValue defaults unknown to user', () {
      expect(UserRole.fromValue(null), UserRole.user);
      expect(UserRole.fromValue('guest'), UserRole.user);
    });

    test('isStation covers station and stationOwner', () {
      expect(UserRole.station.isStation, isTrue);
      expect(UserRole.stationOwner.isStation, isTrue);
      expect(UserRole.user.isStation, isFalse);
    });

    test('isDriver is true only for user role', () {
      expect(UserRole.user.isDriver, isTrue);
      expect(UserRole.station.isDriver, isFalse);
      expect(UserRole.admin.isDriver, isFalse);
    });
  });
}
