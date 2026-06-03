import 'package:flutter/foundation.dart';

/// Read-only metadata from Google Places (never written to Firestore).
@immutable
class ExternalPlaceMetadata {
  const ExternalPlaceMetadata({
    required this.placeId,
    this.rating,
    this.userRatingsTotal,
    this.chargerTypeHint,
    this.isOpenNow,
    this.businessStatus,
    this.connectorCount,
    this.maxChargeRateKw,
    this.connectorTypes,
  });

  final String placeId;
  final double? rating;
  final int? userRatingsTotal;
  final String? chargerTypeHint;
  final bool? isOpenNow;
  final String? businessStatus;
  final int? connectorCount;
  final double? maxChargeRateKw;
  final List<String>? connectorTypes;
}
