import 'package:flutter/foundation.dart';

import 'station_model.dart';

/// Firestore-backed partner station payload for map/booking UI.
@immutable
class PartnerMapData {
  const PartnerMapData({required this.station});

  final StationModel station;

  bool get isApproved => station.status.isPublicOnMap;
  bool get canBook =>
      isApproved && station.availablePorts > 0 && station.shipmentBookingEnabled;
}
