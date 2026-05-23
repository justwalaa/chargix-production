import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../models/vehicle_model.dart';
import 'base_firestore_service.dart';

class VehiclesFirestoreService extends BaseFirestoreService {
  VehiclesFirestoreService({super.firestore});

  CollectionReference<Map<String, dynamic>> get _vehicles =>
      collection(FirestorePaths.vehicles);

  Future<List<VehicleModel>> getVehiclesForUser(String userId) => run(() async {
        final query =
            await _vehicles.where('userId', isEqualTo: userId).get();
        final list =
            query.docs.map((d) => parseDoc(d, VehicleModel.fromMap)).toList();
        list.sort((a, b) {
          if (a.isDefault == b.isDefault) {
            return 0;
          }
          return a.isDefault ? -1 : 1;
        });
        return list;
      }, context: 'getVehiclesForUser');

  Stream<List<VehicleModel>> watchVehiclesForUser(String userId) {
    return runStream(
      () => _vehicles.where('userId', isEqualTo: userId).snapshots().map((snap) {
            final list =
                snap.docs.map((d) => parseDoc(d, VehicleModel.fromMap)).toList();
            list.sort((a, b) {
              if (a.isDefault == b.isDefault) {
                return 0;
              }
              return a.isDefault ? -1 : 1;
            });
            return list;
          }),
      context: 'watchVehiclesForUser',
    );
  }

  Future<void> upsertVehicle(VehicleModel vehicle, {required bool isCreate}) =>
      run(() async {
        final data = withWriteTimestamps(
          data: vehicle.toMap(),
          isCreate: isCreate,
        );
        await _vehicles.doc(vehicle.id).set(data, SetOptions(merge: true));
      }, context: 'upsertVehicle');

  Future<void> deleteVehicle(String id) => run(() async {
        await _vehicles.doc(id).delete();
      }, context: 'deleteVehicle');
}
