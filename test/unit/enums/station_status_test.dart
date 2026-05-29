import 'package:chargix_production/models/enums/station_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StationStatus', () {
    test('fromValue normalizes pendingApproval aliases', () {
      expect(StationStatus.fromValue('pendingApproval'), StationStatus.pending);
      expect(StationStatus.fromValue('pending_approval'), StationStatus.pending);
    });

    test('fromValue defaults null or empty to pending', () {
      expect(StationStatus.fromValue(null), StationStatus.pending);
      expect(StationStatus.fromValue(''), StationStatus.pending);
    });

    test('isPublicOnMap is true for approved and active', () {
      expect(StationStatus.approved.isPublicOnMap, isTrue);
      expect(StationStatus.active.isPublicOnMap, isTrue);
      expect(StationStatus.pending.isPublicOnMap, isFalse);
      expect(StationStatus.rejected.isPublicOnMap, isFalse);
    });

    test('isPendingApproval and isRejected flags', () {
      expect(StationStatus.pending.isPendingApproval, isTrue);
      expect(StationStatus.rejected.isRejected, isTrue);
      expect(StationStatus.active.isPendingApproval, isFalse);
    });
  });
}
