import '../../core/result/data_state.dart';
import '../../models/charging_station.dart';
import '../../models/station_model.dart';
import '../firestore/stations_firestore_service.dart';

class StationRepository {
  StationRepository({StationsFirestoreService? service})
      : _service = service ?? StationsFirestoreService();

  static final StationRepository instance = StationRepository();

  final StationsFirestoreService _service;

  /// Chargix partner station eligible for the map (approval-independent).
  static bool isMapPartnerStation(StationModel station) {
    if (station.id.startsWith('demo-')) {
      return false;
    }
    final ownerId = station.ownerUserId;
    if (ownerId == null || ownerId.isEmpty) {
      return false;
    }
    if (station.latitude == 0 && station.longitude == 0) {
      return false;
    }
    if (station.latitude.isNaN ||
        station.longitude.isNaN ||
        station.latitude < -90 ||
        station.latitude > 90) {
      return false;
    }
    return true;
  }

  static List<StationModel> onlyMapPartners(List<StationModel> stations) {
    return stations.where(isMapPartnerStation).toList(growable: false);
  }

  /// Live Chargix partner stations for the map (all registered partners).
  Stream<List<StationModel>> watchMapPartnerStations() {
    return _service.watchPartnerStationsForMap().map(onlyMapPartners);
  }

  Stream<List<StationModel>> watchActiveStations() => watchMapPartnerStations();

  Stream<List<ChargingStation>> watchActiveChargingStations() {
    return watchMapPartnerStations().map(
      (list) => list.map((s) => s.toChargingStation()).toList(growable: false),
    );
  }

  Future<DataState<List<StationModel>>> fetchMapPartnerStations() async {
    try {
      final all = await _service.getPartnerStationsForMap();
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
