import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/tokens/tokens.dart';
import '../splash/splash_screen.dart';

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
            const Icon(Icons.cancel_outlined, size: 64, color: Colors.redAccent),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Registration not approved',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your station application was reviewed and could not be approved '
              'at this time. Contact support@chargix.app for details.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                await AuthService.instance.signOut();
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const SplashScreen(),
                  ),
                  (_) => false,
                );
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
