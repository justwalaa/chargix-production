import 'package:chargix_production/core/result/data_state.dart';
import 'package:chargix_production/data/firestore/stations_firestore_service.dart';
import 'package:chargix_production/data/repositories/station_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_data.dart';
import '../helpers/firestore_setup.dart';

void main() {
  group('Station flow', () {
    test('loads seeded partner station from Firestore', () async {
      final db = FirestoreTestSetup.fresh();
      final station = FakeData.station(
        id: 'partner-hub',
        ownerUserId: 'owner-99',
      );
      await FirestoreTestSetup.seedStation(db, station);

      final repository = StationRepository(
        service: StationsFirestoreService(firestore: db),
      );

      final result = await repository.getStation('partner-hub');
      expect(result, isA<DataSuccess>());
      expect((result as DataSuccess).data.name, station.name);
    });

    test('onlyMapPartners excludes demo stations', () async {
      final db = FirestoreTestSetup.fresh();
      await FirestoreTestSetup.seedStation(
        db,
        FakeData.station(id: 'demo-bad', ownerUserId: 'o1'),
      );
      await FirestoreTestSetup.seedStation(
        db,
        FakeData.station(id: 'real-good', ownerUserId: 'o1'),
      );

      final all = await StationsFirestoreService(firestore: db)
          .getPartnerStationsForMap();
      final partners = StationRepository.onlyMapPartners(all);

      expect(partners.length, 1);
      expect(partners.first.id, 'real-good');
    });
  });
}
