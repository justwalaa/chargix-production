import 'package:flutter/foundation.dart';

import 'station_model.dart';

/// Firestore-backed partner station payload for map/booking UI.
@immutable
class PartnerMapData {
  const PartnerMapData({required this.station});

  final StationModel station;

  bool get isApproved => true;

  bool get canBook =>
      station.availablePorts > 0 && station.shipmentBookingEnabled;
}
