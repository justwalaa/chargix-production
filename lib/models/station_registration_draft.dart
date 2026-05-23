import 'package:flutter/foundation.dart';

import 'operating_hours_model.dart';

/// In-memory station owner onboarding payload (submitted as pending Firestore doc).
@immutable
class StationRegistrationDraft {
  const StationRegistrationDraft({
    required this.stationName,
    required this.contactEmail,
    required this.contactPhone,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.operatingHours,
    required this.managerName,
    this.managerNationalId,
    this.backupContactPhone,
    this.logoUrl,
    this.stationImageUrl,
  });

  final String stationName;
  final String contactEmail;
  final String contactPhone;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final OperatingHoursModel operatingHours;
  final String managerName;
  final String? managerNationalId;
  final String? backupContactPhone;
  final String? logoUrl;
  final String? stationImageUrl;
}
