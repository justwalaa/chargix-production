import 'package:cloud_firestore/cloud_firestore.dart';

/// Parsing and serialization helpers shared across Firestore models.
abstract final class FirestoreHelpers {
  static String requireString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    if (value != null) {
      return value.toString();
    }
    return '';
  }

  static String? optionalString(Map<String, dynamic>? map, String key) {
    if (map == null) {
      return null;
    }
    final value = map[key];
    if (value == null) {
      return null;
    }
    final s = value.toString();
    return s.isEmpty ? null : s;
  }

  static int requireInt(Map<String, dynamic> map, String key, {int fallback = 0}) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static double requireDouble(
    Map<String, dynamic> map,
    String key, {
    double fallback = 0,
  }) {
    final value = map[key];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static bool requireBool(Map<String, dynamic> map, String key, {bool fallback = false}) {
    final value = map[key];
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return fallback;
  }

  static List<String> stringList(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static DateTime? timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  static Timestamp? dateTimeToTimestamp(DateTime? value) {
    if (value == null) {
      return null;
    }
    return Timestamp.fromDate(value);
  }

  static Map<String, dynamic> serverTimestampsOnWrite({
    required bool isCreate,
    DateTime? explicitUpdatedAt,
  }) {
    return {
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': explicitUpdatedAt != null
          ? Timestamp.fromDate(explicitUpdatedAt)
          : FieldValue.serverTimestamp(),
    };
  }

  static GeoPoint geoPointFromMap(Map<String, dynamic> map) {
    final lat = requireDouble(map, 'latitude');
    final lng = requireDouble(map, 'longitude');
    return GeoPoint(lat, lng);
  }

  static Map<String, double> geoPointToLatLngMap(GeoPoint point) {
    return {
      'latitude': point.latitude,
      'longitude': point.longitude,
    };
  }

  static GeoPoint latLngToGeoPoint(double latitude, double longitude) {
    return GeoPoint(latitude, longitude);
  }
}
