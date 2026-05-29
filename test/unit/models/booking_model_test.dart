import 'package:chargix_production/models/booking_model.dart';
import 'package:chargix_production/models/enums/booking_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('BookingModel', () {
    test('toMap and fromMap round-trip preserves fields', () {
      final original = FakeData.booking();
      final map = original.toMap();
      map['createdAt'] = Timestamp.fromDate(original.createdAt!);
      map['scheduledStart'] = Timestamp.fromDate(original.scheduledStart!);
      map['scheduledEnd'] = Timestamp.fromDate(original.scheduledEnd!);

      final restored = BookingModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.status, BookingStatus.pending);
      expect(restored.priceTotal, original.priceTotal);
    });

    test('fromMap maps confirmed status to approved', () {
      final map = FakeData.booking(status: BookingStatus.approved).toMap();
      map['status'] = 'confirmed';
      expect(BookingModel.fromMap(map).status, BookingStatus.approved);
    });
  });
}
