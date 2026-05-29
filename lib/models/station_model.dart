import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/firebase/firestore_helpers.dart';
import 'charging_station.dart';
import 'enums/station_status.dart';
import 'operating_hours_model.dart';

/// Firestore `stations/{id}` — map + admin dashboard source of truth.
@immutable
class StationModel {
  const StationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.availablePorts,
    required this.totalPorts,
    required this.pricePerKwh,
    required this.rating,
    this.status = StationStatus.active,
    this.amenities = const [],
    this.imageUrl,
    this.operatorId,
    this.ownerUserId,
    this.description,
    this.operatingHours = const OperatingHoursModel(),
    this.shipmentBookingEnabled = true,
    this.isPublic = true,
    this.city,
    this.contactEmail,
    this.contactPhone,
    this.managerName,
    this.managerNationalId,
    this.backupContactPhone,
    this.logoUrl,
    this.qrPayload,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int availablePorts;
  final int totalPorts;
  final double pricePerKwh;
  final double rating;
  final StationStatus status;
  final List<String> amenities;
  final String? imageUrl;
  final String? operatorId;
  final String? ownerUserId;
  final String? description;
  final OperatingHoursModel operatingHours;
  final bool shipmentBookingEnabled;
  final bool isPublic;
  final String? city;
  final String? contactEmail;
  final String? contactPhone;
  final String? managerName;
  final String? managerNationalId;
  final String? backupContactPhone;
  final String? logoUrl;
  final String? qrPayload;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GeoPoint get location => GeoPoint(latitude, longitude);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'availablePorts': availablePorts,
      'totalPorts': totalPorts,
      'pricePerKwh': pricePerKwh,
      'rating': rating,
      'status': status.value,
      'amenities': amenities,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (operatorId != null) 'operatorId': operatorId,
      if (ownerUserId != null) 'ownerUserId': ownerUserId,
      if (description != null) 'description': description,
      'operatingHours': operatingHours.toMap(),
      'shipmentBookingEnabled': shipmentBookingEnabled,
      'isPublic': isPublic,
      if (city != null) 'city': city,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (managerName != null) 'managerName': managerName,
      if (managerNationalId != null) 'managerNationalId': managerNationalId,
      if (backupContactPhone != null) 'backupContactPhone': backupContactPhone,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (qrPayload != null) 'qrPayload': qrPayload,
      if (createdAt != null)
        'createdAt': FirestoreHelpers.dateTimeToTimestamp(createdAt),
      if (updatedAt != null)
        'updatedAt': FirestoreHelpers.dateTimeToTimestamp(updatedAt),
    };
  }

  factory StationModel.fromMap(Map<String, dynamic> map) {
    final geo = map['location'];
    double lat = FirestoreHelpers.requireDouble(map, 'latitude');
    double lng = FirestoreHelpers.requireDouble(map, 'longitude');
    if (lat == 0 && lng == 0) {
      lat = FirestoreHelpers.requireDouble(map, 'lat');
      lng = FirestoreHelpers.requireDouble(map, 'lng');
    }
    if (geo is GeoPoint) {
      lat = geo.latitude;
      lng = geo.longitude;
    }

    return StationModel(
      id: FirestoreHelpers.requireString(map, 'id'),
      name: FirestoreHelpers.requireString(map, 'name'),
      address: FirestoreHelpers.requireString(map, 'address'),
      latitude: lat,
      longitude: lng,
      availablePorts: FirestoreHelpers.requireInt(map, 'availablePorts'),
      totalPorts: FirestoreHelpers.requireInt(map, 'totalPorts'),
      pricePerKwh: FirestoreHelpers.requireDouble(map, 'pricePerKwh'),
      rating: FirestoreHelpers.requireDouble(map, 'rating'),
      status: StationStatus.fromValue(
        FirestoreHelpers.optionalString(map, 'status'),
      ),
      amenities: FirestoreHelpers.stringList(map, 'amenities'),
      imageUrl: FirestoreHelpers.optionalString(map, 'imageUrl'),
      operatorId: FirestoreHelpers.optionalString(map, 'operatorId'),
      ownerUserId: FirestoreHelpers.optionalString(map, 'ownerUserId') ??
          FirestoreHelpers.optionalString(map, 'ownerId'),
      description: FirestoreHelpers.optionalString(map, 'description'),
      operatingHours: OperatingHoursModel.fromMap(
        map['operatingHours'] as Map<String, dynamic>?,
      ),
      shipmentBookingEnabled: FirestoreHelpers.requireBool(
        map,
        'shipmentBookingEnabled',
        fallback: true,
      ),
      isPublic: FirestoreHelpers.requireBool(map, 'isPublic', fallback: true),
      city: FirestoreHelpers.optionalString(map, 'city'),
      contactEmail: FirestoreHelpers.optionalString(map, 'contactEmail'),
      contactPhone: FirestoreHelpers.optionalString(map, 'contactPhone'),
      managerName: FirestoreHelpers.optionalString(map, 'managerName'),
      managerNationalId:
          FirestoreHelpers.optionalString(map, 'managerNationalId'),
      backupContactPhone:
          FirestoreHelpers.optionalString(map, 'backupContactPhone'),
      logoUrl: FirestoreHelpers.optionalString(map, 'logoUrl'),
      qrPayload: FirestoreHelpers.optionalString(map, 'qrPayload'),
      createdAt: FirestoreHelpers.timestampToDateTime(map['createdAt']),
      updatedAt: FirestoreHelpers.timestampToDateTime(map['updatedAt']),
    );
  }

  /// UI map layer (existing [ChargingStation] widget model).
  ChargingStation toChargingStation() {
    return ChargingStation(
      id: id,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      availablePorts: availablePorts,
      totalPorts: totalPorts,
      pricePerKwh: pricePerKwh,
      rating: rating,
    );
  }

  factory StationModel.fromChargingStation(ChargingStation station) {
    return StationModel(
      id: station.id,
      name: station.name,
      address: station.address,
      latitude: station.latitude,
      longitude: station.longitude,
      availablePorts: station.availablePorts,
      totalPorts: station.totalPorts,
      pricePerKwh: station.pricePerKwh,
      rating: station.rating,
      status: StationStatus.approved,
      isPublic: true,
    );
  }
}
