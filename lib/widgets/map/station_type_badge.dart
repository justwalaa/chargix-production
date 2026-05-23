import 'package:flutter/material.dart';

import '../../models/map_station.dart';
import '../../theme/tokens/tokens.dart';

/// Partner vs external label for map previews and lists.
class StationTypeBadge extends StatelessWidget {
  const StationTypeBadge({super.key, required this.station});

  final MapStation station;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPartner = station.isPartner;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isPartner
            ? scheme.primary.withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isPartner
              ? scheme.primary.withValues(alpha: 0.35)
              : scheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPartner ? Icons.verified_rounded : Icons.public_rounded,
            size: 16,
            color: isPartner ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            isPartner ? 'Chargix Partner' : 'External Station',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isPartner ? scheme.primary : scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
