import 'package:flutter/material.dart';

import '../../theme/app_gradients.dart';
import '../../theme/tokens/tokens.dart';

/// Chargix wordmark + EV / logistics icon.
class ChargixBrandLockup extends StatelessWidget {
  const ChargixBrandLockup({
    super.key,
    this.compact = false,
    this.showTagline = true,
  });

  final bool compact;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 28.0 : 34.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 10 : 12),
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                    blurRadius: compact ? 14 : 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.electric_bolt_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: compact ? 28 : 34,
              ),
            ),
            SizedBox(width: compact ? AppSpacing.md : AppSpacing.lg),
            Text(
              'Chargix',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
            ),
          ],
        ),
        if (showTagline) ...[
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          Text(
            'EV charging · smart logistics · one network',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
          ),
        ],
      ],
    );
  }
}
