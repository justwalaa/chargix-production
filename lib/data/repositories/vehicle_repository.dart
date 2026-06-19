import '../../core/result/data_state.dart';
import '../../models/vehicle_model.dart';
import '../firestore/vehicles_firestore_service.dart';

class VehicleRepository {
  VehicleRepository({VehiclesFirestoreService? service})
      : _service = service ?? VehiclesFirestoreService();

  static final VehicleRepository instance = VehicleRepository();

  final VehiclesFirestoreService _service;

  Stream<List<VehicleModel>> watchVehiclesForUser(String userId) =>
      _service.watchVehiclesForUser(userId);

  Future<DataState<List<VehicleModel>>> fetchVehiclesForUser(String userId) async {
    try {
      final list = await _service.getVehiclesForUser(userId);
      return DataSuccess(list);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  Future<DataState<void>> deleteVehicle(String vehicleId) async {
    try {
      await _service.deleteVehicle(vehicleId);
      return const DataSuccess(null);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  Future<DataState<void>> saveVehicle(VehicleModel vehicle) async {
    try {
      final existing = await _service.getVehiclesForUser(vehicle.userId);
      final isCreate = !existing.any((v) => v.id == vehicle.id);
      await _service.upsertVehicle(vehicle, isCreate: isCreate);
      return const DataSuccess(null);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }
}
