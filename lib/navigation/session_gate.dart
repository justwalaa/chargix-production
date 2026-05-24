import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/auth/session_loading_screen.dart';

/// Legacy StreamBuilder gate — production routing uses [core/routing/session_gate.dart]
/// via [ChargixApp] auth listener. Kept for optional embedded auth shells.
class SessionGate extends StatelessWidget {
  final WidgetBuilder authenticatedBuilder;
  final WidgetBuilder unauthenticatedBuilder;

  const SessionGate({
    super.key,
    required this.authenticatedBuilder,
    required this.unauthenticatedBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still waiting for the first auth event
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SessionLoadingScreen();
        }

        // User is signed in
        if (snapshot.hasData && snapshot.data != null) {
          return authenticatedBuilder(context);
        }

        // No user – show login/onboarding
        return unauthenticatedBuilder(context);
      },
    );
  }
}
