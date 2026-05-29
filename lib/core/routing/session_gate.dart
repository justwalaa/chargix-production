import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/chargix_data.dart';
import '../../models/enums/user_role.dart';
import '../../models/station_model.dart';
import '../../models/user_model.dart';
import '../../navigation/main_navigation.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/station/station_main_navigation.dart';
import '../../screens/station/station_owner_onboarding_screen.dart';
import '../result/data_state.dart';

/// Resolves the correct home shell after splash / login from Firestore profile.
abstract final class SessionGate {
  static const Duration _bootstrapTimeout = Duration(seconds: 20);

  static const int _maxRetries = 6;
  static const Duration _retryBase = Duration(milliseconds: 600);

  static Future<Widget> resolveHome() async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      final uid = authUser?.uid;
      if (uid == null) {
        return const LoginScreen();
      }

      var profile = await _loadProfile(uid);
      profile ??= await _bootstrapProfile(authUser!);
      if (profile == null) {
        debugPrint(
          'Chargix SessionGate: no profile for $uid — returning login.',
        );
        return const LoginScreen();
      }

      if (await _isStationOperator(uid, profile)) {
        return await _resolveStationHome(uid: uid, profile: profile);
      }

      debugPrint('Chargix SessionGate: driver → MainNavigation ($uid)');
      return const MainNavigation();
    } on TimeoutException catch (e, st) {
      debugPrint('Chargix SessionGate: bootstrap timed out: $e\n$st');
      return const LoginScreen();
    } catch (e, st) {
      debugPrint('Chargix SessionGate: resolveHome failed: $e\n$st');
      return const LoginScreen();
    }
  }

  /// Station operators must never land on the driver shell.
  static Future<bool> _isStationOperator(String uid, UserModel profile) async {
    if (profile.role.isStation) {
      return true;
    }
    final stationId = profile.stationId;
    if (stationId != null && stationId.isNotEmpty) {
      return true;
    }

    final owned = await ChargixData.stations.getStation(uid);
    final station = owned.dataOrNull;
    if (station != null) {
      final ownerId = station.ownerUserId;
      if (ownerId == uid || station.id == uid) {
        debugPrint(
          'Chargix SessionGate: station doc detected for $uid '
          '(role=${profile.role.value})',
        );
        return true;
      }
    }
    return false;
  }

  static Future<UserModel?> _loadProfile(String uid) async {
    final state =
        await ChargixData.users.getUser(uid).timeout(_bootstrapTimeout);
    if (state is DataSuccess<UserModel>) {
      return state.data;
    }
    if (state is DataError<UserModel>) {
      debugPrint('Chargix SessionGate: getUser error: ${state.error}');
    }
    return null;
  }

  static Future<UserModel?> _bootstrapProfile(User authUser) async {
    final uid = authUser.uid;
    final phone = (authUser.phoneNumber ?? '').trim();
    final email = (authUser.email ?? '').trim();

    if (phone.isEmpty && email.isEmpty) {
      return null;
    }

    if (phone.isEmpty && email.isNotEmpty) {
      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        await Future<void>.delayed(_retryBase * attempt);
        final retry = await _loadProfile(uid);
        if (retry != null) return retry;
      }
      return null;
    }

    if (phone.isEmpty) return null;

    // Do not create a driver profile if this uid already owns a station.
    final stationState = await ChargixData.stations.getStation(uid);
    if (stationState.dataOrNull != null) {
      debugPrint(
        'Chargix SessionGate: station doc exists for $uid — skip driver bootstrap',
      );
      return _loadProfile(uid);
    }

    final result = await ChargixData.users
        .ensureUserAfterSignIn(
          uid: uid,
          phoneE164: phone,
          role: UserRole.user,
        )
        .timeout(_bootstrapTimeout);

    if (result is DataSuccess<UserModel>) {
      return result.data;
    }
    return null;
  }

  static Future<Widget> _resolveStationHome({
    required String uid,
    required UserModel profile,
  }) async {
    final stationId = profile.stationId ?? uid;

    StationModel? station;
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(_retryBase * attempt);
      }
      final state = await ChargixData.stations
          .getStation(stationId)
          .timeout(_bootstrapTimeout);
      station = state.dataOrNull;
      if (station != null) break;
    }

    if (station == null) {
      return StationOwnerOnboardingScreen(
        ownerUserId: uid,
        phoneE164: profile.phoneE164,
      );
    }

    debugPrint(
      'Chargix SessionGate: station operator → dashboard ($stationId)',
    );
    return StationMainNavigation(stationId: stationId);
  }
}
