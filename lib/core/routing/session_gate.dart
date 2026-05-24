import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/chargix_data.dart';
import '../../models/enums/user_role.dart';
import '../../models/station_model.dart';
import '../../models/user_model.dart';
import '../../navigation/main_navigation.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/station/station_approval_pending_screen.dart';
import '../../screens/station/station_main_navigation.dart';
import '../../screens/station/station_owner_onboarding_screen.dart';
import '../../screens/station/station_rejected_screen.dart';
import '../result/data_state.dart';

/// Resolves the correct home shell after splash / login from Firestore profile.
abstract final class SessionGate {
  static const Duration _bootstrapTimeout = Duration(seconds: 20);

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

      if (profile.role.isStation) {
        return await _resolveStationHome(uid: uid, profile: profile);
      }
      return const MainNavigation();
    } on TimeoutException catch (e, st) {
      debugPrint('Chargix SessionGate: bootstrap timed out: $e\n$st');
      return const LoginScreen();
    } catch (e, st) {
      debugPrint('Chargix SessionGate: resolveHome failed: $e\n$st');
      return const LoginScreen();
    }
  }

  static Future<UserModel?> _loadProfile(String uid) async {
    final state = await ChargixData.users
        .getUser(uid)
        .timeout(_bootstrapTimeout);
    if (state is DataSuccess<UserModel>) {
      return state.data;
    }
    if (state is DataError<UserModel>) {
      debugPrint('Chargix SessionGate: getUser error: ${state.error}');
    }
    return null;
  }

  /// Creates a minimal Firestore profile when Auth succeeded but `users/{uid}` is missing.
  static Future<UserModel?> _bootstrapProfile(User authUser) async {
    final uid = authUser.uid;
    final phone = (authUser.phoneNumber ?? '').trim();
    final email = (authUser.email ?? '').trim();

    if (phone.isEmpty && email.isEmpty) {
      debugPrint(
        'Chargix SessionGate: cannot bootstrap $uid — no phone or email on Auth user.',
      );
      return null;
    }

    // Station email/password accounts must already have a Firestore profile with
    // a real phone from registration — never store email in phoneE164.
    if (phone.isEmpty && email.isNotEmpty) {
      debugPrint(
        'Chargix SessionGate: station auth without phone on Firebase user — '
        'profile must exist in Firestore.',
      );
      return null;
    }

    if (phone.isEmpty) {
      return null;
    }

    final role = UserRole.user;

    debugPrint(
      'Chargix SessionGate: bootstrapping driver profile for $uid.',
    );

    final result = await ChargixData.users
        .ensureUserAfterSignIn(
          uid: uid,
          phoneE164: phone,
          role: role,
        )
        .timeout(_bootstrapTimeout);

    if (result is DataSuccess<UserModel>) {
      return result.data;
    }
    if (result is DataError<UserModel>) {
      debugPrint(
        'Chargix SessionGate: ensureUserAfterSignIn failed: ${result.error}',
      );
    }
    return null;
  }

  static Future<Widget> _resolveStationHome({
    required String uid,
    required UserModel profile,
  }) async {
    final stationId = profile.stationId ?? uid;
    final stationState = await ChargixData.stations
        .getStation(stationId)
        .timeout(_bootstrapTimeout);

    if (stationState is DataError<StationModel>) {
      debugPrint(
        'Chargix SessionGate: getStation($stationId) error: ${stationState.error}',
      );
    }

    final station = stationState.dataOrNull;
    if (station == null) {
      return StationOwnerOnboardingScreen(
        ownerUserId: uid,
        phoneE164: profile.phoneE164,
      );
    }
    if (station.status.isPendingApproval) {
      return StationApprovalPendingScreen(stationId: stationId);
    }
    if (station.status.isRejected) {
      return StationRejectedScreen(stationId: stationId);
    }
    if (station.status.isPublicOnMap) {
      return StationMainNavigation(stationId: stationId);
    }
    return StationOwnerOnboardingScreen(
      ownerUserId: uid,
      phoneE164: profile.phoneE164,
    );
  }
}
