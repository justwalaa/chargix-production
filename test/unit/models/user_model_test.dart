import 'package:chargix_production/models/user_model.dart';
import 'package:chargix_production/models/enums/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('UserModel', () {
    test('toMap and fromMap round-trip', () {
      final original = FakeData.user(role: UserRole.stationOwner);
      final restored = UserModel.fromMap(original.toMap());

      expect(restored.uid, original.uid);
      expect(restored.phoneE164, original.phoneE164);
      expect(restored.role, UserRole.stationOwner);
    });

    test('fromMap resolves uid from id field fallback', () {
      final map = FakeData.user(uid: 'abc').toMap()..remove('uid');
      map['id'] = 'abc';
      expect(UserModel.fromMap(map).uid, 'abc');
    });

    test('copyWith preserves uid and updates role', () {
      final user = FakeData.user();
      final updated = user.copyWith(role: UserRole.admin);
      expect(updated.uid, user.uid);
      expect(updated.role, UserRole.admin);
    });
  });
}
