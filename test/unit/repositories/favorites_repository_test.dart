import 'package:chargix_production/core/result/data_state.dart';
import 'package:chargix_production/data/repositories/favorites_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';
import '../../helpers/firestore_setup.dart';

void main() {
  group('FavoritesRepository', () {
    test('toggleFavorite add persists favorite document', () async {
      final db = FirestoreTestSetup.fresh();
      final repo = FavoritesRepository(
        service: FirestoreTestSetup.favoritesService(db),
      );

      final result = await repo.toggleFavorite(
        userId: 'u1',
        stationId: 's1',
        add: true,
      );

      expect(result, isA<DataSuccess<void>>());

      final snap = await db.collection('favorites').doc('u1_s1').get();
      expect(snap.exists, isTrue);
      expect(snap.data()?['stationId'], 's1');
    });

    test('toggleFavorite remove deletes favorite document', () async {
      final db = FirestoreTestSetup.fresh();
      await FirestoreTestSetup.seedFavorite(
        db,
        FakeData.favorite(userId: 'u1', stationId: 's1'),
      );
      final repo = FavoritesRepository(
        service: FirestoreTestSetup.favoritesService(db),
      );

      final result = await repo.toggleFavorite(
        userId: 'u1',
        stationId: 's1',
        add: false,
      );

      expect(result, isA<DataSuccess<void>>());
      final snap = await db.collection('favorites').doc('u1_s1').get();
      expect(snap.exists, isFalse);
    });

    test('watchFavoriteStationIds emits seeded ids', () async {
      final db = FirestoreTestSetup.fresh();
      await FirestoreTestSetup.seedFavorite(
        db,
        FakeData.favorite(userId: 'u1', stationId: 's1'),
      );
      final repo = FavoritesRepository(
        service: FirestoreTestSetup.favoritesService(db),
      );

      final ids = await repo.watchFavoriteStationIds('u1').first;
      expect(ids, {'s1'});
    });
  });
}
