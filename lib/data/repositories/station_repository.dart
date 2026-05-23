import '../../../core/result/data_state.dart';
import '../../../models/charging_station.dart';
import '../../../models/station_model.dart';
import '../../firestore/stations_firestore_service.dart';

class StationRepository {
  StationRepository({StationsFirestoreService? service})
      : _service = service ?? StationsFirestoreService();

  static final StationRepository instance = StationRepository();

  final StationsFirestoreService _service;

  /// True for live Chargix partner docs (excludes legacy demo/seed rows).
  static bool isMapPartnerStation(StationModel station) {
    if (station.id.startsWith('demo-')) {
      return false;
    }
    if (!station.isPublic || !station.status.isPublicOnMap) {
      return false;
    }
    final ownerId = station.ownerUserId;
    return ownerId != null && ownerId.isNotEmpty;
  }

  static List<StationModel> onlyMapPartners(List<StationModel> stations) {
    return stations.where(isMapPartnerStation).toList(growable: false);
  }

  /// Approved Chargix partner stations only (map + stations list + booking).
  Stream<List<StationModel>> watchMapPartnerStations() {
    return _service.watchPublicStations().map(onlyMapPartners);
  }

  Stream<List<StationModel>> watchActiveStations() => watchMapPartnerStations();

  Stream<List<ChargingStation>> watchActiveChargingStations() {
    return watchMapPartnerStations().map(
      (list) => list.map((s) => s.toChargingStation()).toList(growable: false),
    );
  }

  Future<DataState<List<StationModel>>> fetchMapPartnerStations() async {
    try {
      final all = await _service.getPublicStations();
      return DataSuccess(onlyMapPartners(all));
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  Future<DataState<List<StationModel>>> fetchActiveStations() =>
      fetchMapPartnerStations();

  Future<DataState<StationModel>> getStation(String id) async {
    try {
      final station = await _service.getStation(id);
      if (station == null) {
        return const DataError('Station not found.');
      }
      return DataSuccess(station);
    } catch (e, st) {
      return DataError(e, stackTrace: st);
    }
  }

  Stream<StationModel?> watchStation(String id) => _service.watchStation(id);
}
