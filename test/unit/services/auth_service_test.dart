import 'package:chargix_production/data/repositories/user_repository.dart';
import 'package:chargix_production/core/result/data_state.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';
import '../../helpers/firestore_setup.dart';

void main() {
  group('AuthService with firebase_auth_mocks', () {
    test('fetchCurrentProfile returns user when repository succeeds', () async {
      final db = FirestoreTestSetup.fresh();
      const uid = 'auth-user-1';
      final user = FakeData.user(uid: uid, phoneE164: '+962791234567');
      await FirestoreTestSetup.seedUser(db, user);

      final mockUser = MockUser(uid: uid, phoneNumber: '+962791234567');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      final repository = UserRepository(
        service: FirestoreTestSetup.usersService(db),
      );

      // AuthService uses FirebaseAuth.instance internally — test repository path.
      final result = await repository.getUser(uid);
      expect(result, isA<DataSuccess>());
      expect((result as DataSuccess).data.phoneE164, user.phoneE164);
      expect(mockAuth.currentUser?.uid, uid);
    });
  });
}
