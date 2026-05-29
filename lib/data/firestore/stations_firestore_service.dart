import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../models/station_model.dart';
import 'base_firestore_service.dart';

class StationsFirestoreService extends BaseFirestoreService {
  StationsFirestoreService({super.firestore});

  CollectionReference<Map<String, dynamic>> get _stations =>
      collection(FirestorePaths.stations);

  Future<List<StationModel>> getPublicStations() => run(() async {
        final query = await _stations.where('isPublic', isEqualTo: true).get();
        return query.docs.map((d) => parseDoc(d, StationModel.fromMap)).toList();
      }, context: 'getPublicStations');

  /// All registered partner stations for the map (not filtered by approval).
  Future<List<StationModel>> getPartnerStationsForMap() => run(() async {
        final query = await _stations.get();
        return query.docs.map((d) => parseDoc(d, StationModel.fromMap)).toList();
      }, context: 'getPartnerStationsForMap');

  Stream<List<StationModel>> watchPublicStations() {
    return runStream(
      () => _stations.where('isPublic', isEqualTo: true).snapshots().map(
            (snap) =>
                snap.docs.map((d) => parseDoc(d, StationModel.fromMap)).toList(),
          ),
      context: 'watchPublicStations',
    );
  }

  /// Live partner station updates for the map layer.
  Stream<List<StationModel>> watchPartnerStationsForMap() {
    return runStream(
      () => _stations.snapshots().map(
            (snap) =>
                snap.docs.map((d) => parseDoc(d, StationModel.fromMap)).toList(),
          ),
      context: 'watchPartnerStationsForMap',
    );
  }

  Future<StationModel?> getStation(String id) => run(() async {
        final snap = await _stations.doc(id).get();
        if (!snap.exists) {
          return null;
        }
        return parseDoc(snap, StationModel.fromMap);
      }, context: 'getStation');

  Stream<StationModel?> watchStation(String id) {
    return runStream(
      () => _stations.doc(id).snapshots().map((snap) {
        if (!snap.exists) {
          return null;
        }
        return parseDoc(snap, StationModel.fromMap);
      }),
      context: 'watchStation',
    );
  }

  Future<void> upsertStation(StationModel station, {required bool isCreate}) =>
      run(() async {
        final data = withWriteTimestamps(
          data: station.toMap(),
          isCreate: isCreate,
        );
        await _stations.doc(station.id).set(data, SetOptions(merge: true));
      }, context: 'upsertStation');

  Future<int> countStations() => run(() async {
        final snap = await _stations.count().get();
        return snap.count ?? 0;
      }, context: 'countStations');

  Future<void> batchUpsertStations(List<StationModel> stations) => run(() async {
        final batch = db.batch();
        for (final station in stations) {
          final ref = _stations.doc(station.id);
          batch.set(
            ref,
            withWriteTimestamps(data: station.toMap(), isCreate: true),
            SetOptions(merge: true),
          );
        }
        await batch.commit();
      }, context: 'batchUpsertStations');
}
