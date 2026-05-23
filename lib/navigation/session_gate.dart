import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
          return const _AuthLoadingScreen();
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

/// Minimal dark loading indicator shown while Firebase initialises.
class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF080B14),
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
          ),
        ),
      ),
    );
  }
}
