import 'package:flutter/material.dart';

import '../../models/station_model.dart';
import '../../theme/tokens/tokens.dart';
import '../chargix/premium_card.dart';

class StationListTile extends StatelessWidget {
  const StationListTile({
    super.key,
    required this.station,
    required this.onTap,
  });

  final StationModel station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final portsLabel =
        '${station.availablePorts}/${station.totalPorts} ports open';

    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Icon(
              Icons.ev_station_rounded,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        station.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  station.address,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.bolt, size: 14, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '\$${station.pricePerKwh.toStringAsFixed(2)}/kWh',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.star_rounded, size: 14, color: scheme.tertiary),
                    Text(
                      station.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                portsLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: station.availablePorts > 0
                          ? scheme.primary
                          : scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ],
      ),
    );
  }
}
