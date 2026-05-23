import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../models/station_slot_model.dart';
import 'base_firestore_service.dart';

class StationSlotsFirestoreService extends BaseFirestoreService {
  StationSlotsFirestoreService({super.firestore});

  CollectionReference<Map<String, dynamic>> _slots(String stationId) =>
      db.collection(FirestorePaths.stationSlotsCollection(stationId));

  Stream<List<StationSlotModel>> watchSlots(String stationId) {
    return runStream(
      () => _slots(stationId).snapshots().map(
            (snap) => snap.docs
                .map((d) => parseDoc(d, StationSlotModel.fromMap))
                .toList(),
          ),
      context: 'watchSlots',
    );
  }

  Future<void> upsertSlot(StationSlotModel slot, {required bool isCreate}) =>
      run(() async {
        final data = withWriteTimestamps(
          data: slot.toMap(),
          isCreate: isCreate,
        );
        await _slots(slot.stationId).doc(slot.id).set(data, SetOptions(merge: true));
      }, context: 'upsertSlot');

  Future<void> deleteSlot(String stationId, String slotId) => run(() async {
        await _slots(stationId).doc(slotId).delete();
      }, context: 'deleteSlot');
}
