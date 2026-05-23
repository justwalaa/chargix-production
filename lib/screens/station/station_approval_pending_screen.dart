import 'package:flutter/material.dart';

import '../../theme/app_gradients.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/chargix_brand_lockup.dart';

/// Shown while a partner station awaits admin approval.
class StationApprovalPendingScreen extends StatelessWidget {
  const StationApprovalPendingScreen({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.hero(context),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ChargixBrandLockup(),
                const Spacer(),
                Icon(Icons.hourglass_top_rounded,
                    size: 72, color: scheme.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Application under review',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Your station registration was submitted successfully. '
                  'Chargix will verify your details before activating partner '
                  'bookings on the map.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
                const Spacer(flex: 2),
                Text(
                  'Station ID: $stationId',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
