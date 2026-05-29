import 'package:chargix_production/models/station_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_data.dart';

void main() {
  group('StationModel', () {
    test('toMap and fromMap round-trip', () {
      final original = FakeData.station();
      final restored = StationModel.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.latitude, original.latitude);
      expect(restored.availablePorts, original.availablePorts);
    });

    test('fromMap prefers GeoPoint location over lat/lng fields', () {
      final map = FakeData.station().toMap();
      map['location'] = const GeoPoint(32.0, 36.0);
      final station = StationModel.fromMap(map);
      expect(station.latitude, 32.0);
      expect(station.longitude, 36.0);
    });

    test('toChargingStation and fromChargingStation round-trip core fields', () {
      final station = FakeData.station();
      final charging = station.toChargingStation();
      final restored = StationModel.fromChargingStation(charging);

      expect(restored.id, station.id);
      expect(restored.pricePerKwh, station.pricePerKwh);
      expect(restored.totalPorts, station.totalPorts);
    });

    test('location getter returns GeoPoint', () {
      final station = FakeData.station();
      expect(station.location.latitude, station.latitude);
      expect(station.location.longitude, station.longitude);
    });
  });
}
