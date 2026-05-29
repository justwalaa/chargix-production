import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/tokens/tokens.dart';

/// Shown when a partner station's application was rejected.
///
/// Signing out fires the ChargixApp auth listener which navigates to
/// LoginScreen automatically — no manual navigation needed here.
class StationRejectedScreen extends StatelessWidget {
  const StationRejectedScreen({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application status')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenGutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.cancel_outlined,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Registration not approved',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your station application was reviewed and could not be '
                  'approved at this time. Contact support@chargix.app for details.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                // Sign out — ChargixApp auth listener navigates to LoginScreen.
                await FirebaseAuth.instance.signOut();
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}