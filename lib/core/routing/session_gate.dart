import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/chargix_data.dart';
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
  static Future<Widget> resolveHome() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const LoginScreen();
    }
    final state = await ChargixData.users.getUser(uid);
    if (state is! DataSuccess<UserModel>) {
      return const LoginScreen();
    }
    final profile = state.data;
    if (profile.role.isStation) {
      final stationId = profile.stationId ?? uid;
      final stationState = await ChargixData.stations.getStation(stationId);
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
    return const MainNavigation();
  }
}
