import 'package:chargix_production/core/result/data_state.dart';
import 'package:chargix_production/data/repositories/user_repository.dart';
import 'package:chargix_production/models/enums/user_role.dart';
import 'package:chargix_production/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';
import '../../helpers/firestore_setup.dart';

void main() {
  group('UserRepository', () {
    late UserRepository repository;

    setUp(() {
      final db = FirestoreTestSetup.fresh();
      repository = UserRepository(
        service: FirestoreTestSetup.usersService(db),
      );
    });

    test('getUser returns DataError when profile missing', () async {
      final result = await repository.getUser('missing');
      expect(result, isA<DataError<UserModel>>());
    });

    test('getUser returns DataSuccess for seeded user', () async {
      final db = FirestoreTestSetup.fresh();
      final user = FakeData.user(uid: 'u1');
      await FirestoreTestSetup.seedUser(db, user);
      repository = UserRepository(service: FirestoreTestSetup.usersService(db));

      final result = await repository.getUser('u1');
      expect(result, isA<DataSuccess>());
      expect((result as DataSuccess).data.phoneE164, user.phoneE164);
    });

    test('ensureUserAfterSignIn creates new profile', () async {
      final db = FirestoreTestSetup.fresh();
      repository = UserRepository(service: FirestoreTestSetup.usersService(db));

      final result = await repository.ensureUserAfterSignIn(
        uid: 'new-user',
        phoneE164: '+962791111111',
        role: UserRole.user,
      );

      expect(result, isA<DataSuccess>());
      expect((result as DataSuccess).data.uid, 'new-user');
    });

    test('updateProfile persists changes', () async {
      final db = FirestoreTestSetup.fresh();
      final user = FakeData.user().copyWith(displayName: 'Old');
      await FirestoreTestSetup.seedUser(db, user);
      repository = UserRepository(service: FirestoreTestSetup.usersService(db));

      final updated = user.copyWith(displayName: 'New Name');
      final result = await repository.updateProfile(updated);
      expect(result, isA<DataSuccess<void>>());

      final loaded = await repository.getUser(user.uid);
      expect((loaded as DataSuccess).data.displayName, 'New Name');
    });
  });
}
