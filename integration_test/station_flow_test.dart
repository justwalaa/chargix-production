import 'package:chargix_production/core/result/data_state.dart';
import 'package:chargix_production/data/repositories/station_repository.dart';
import 'package:chargix_production/data/firestore/stations_firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/fake_data.dart';
import '../test/helpers/firestore_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Station flow integration', () {
    test('partner station seeds and loads via repository', () async {
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

    test('onlyMapPartners filters seeded station list', () async {
      final db = FirestoreTestSetup.fresh();
      await FirestoreTestSetup.seedStation(
        db,
        FakeData.station(id: 'demo-bad', ownerUserId: 'o1'),
      );
      await FirestoreTestSetup.seedStation(
        db,
        FakeData.station(id: 'real-good', ownerUserId: 'o1'),
      );

      final service = StationsFirestoreService(firestore: db);
      final all = await service.getPartnerStationsForMap();
      final partners = StationRepository.onlyMapPartners(all);

      expect(partners.length, 1);
      expect(partners.first.id, 'real-good');
    });

    test('isMapPartnerStation gates map eligibility', () {
      expect(
        StationRepository.isMapPartnerStation(FakeData.station()),
        isTrue,
      );
      expect(
        StationRepository.isMapPartnerStation(
          FakeData.station(id: 'demo-x', ownerUserId: 'o'),
        ),
        isFalse,
      );
    });
  });
}
