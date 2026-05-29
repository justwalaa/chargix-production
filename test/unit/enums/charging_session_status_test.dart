import 'package:chargix_production/models/enums/charging_session_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChargingSessionStatus', () {
    test('fromValue resolves known statuses', () {
      expect(
        ChargingSessionStatus.fromValue('charging'),
        ChargingSessionStatus.charging,
      );
      expect(
        ChargingSessionStatus.fromValue('completed'),
        ChargingSessionStatus.completed,
      );
    });

    test('fromValue defaults to idle for unknown', () {
      expect(
        ChargingSessionStatus.fromValue('unknown'),
        ChargingSessionStatus.idle,
      );
      expect(ChargingSessionStatus.fromValue(null), ChargingSessionStatus.idle);
    });
  });
}
