import 'package:flutter/material.dart';

import '../../models/station_model.dart';
import '../booking/book_slot_screen.dart';
import '../../theme/app_gradients.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/premium_card.dart';
import '../../widgets/map/station_type_badge.dart';
import '../../models/map_station.dart';
import '../../utils/map_station_mapper.dart';

/// Partner station details — booking enabled (Chargix Firestore only).
class StationDetailsScreen extends StatefulWidget {
  const StationDetailsScreen({
    super.key,
    required this.partnerStation,
  });

  final StationModel partnerStation;

  @override
  State<StationDetailsScreen> createState() => _StationDetailsScreenState();
}

class _StationDetailsScreenState extends State<StationDetailsScreen> {
  MapStation get _mapStation =>
      MapStationMapper.fromPartner(widget.partnerStation);

  @override
  Widget build(BuildContext context) {
    final station = widget.partnerStation;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Partner station')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenGutter),
        children: [
          StationTypeBadge(station: _mapStation),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(AppRadii.xxl),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.ev_station_rounded, color: Colors.white, size: 40),
                const SizedBox(height: AppSpacing.md),
                Text(
                  station.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  station.address,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PremiumCard(
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.power_rounded,
                  label: 'Availability',
                  value:
                      '${station.availablePorts} of ${station.totalPorts} ports open',
                ),
                const Divider(height: AppSpacing.lg),
                _DetailRow(
                  icon: Icons.bolt_rounded,
                  label: 'Price',
                  value: '\$${station.pricePerKwh.toStringAsFixed(2)} / kWh',
                ),
                const Divider(height: AppSpacing.lg),
                _DetailRow(
                  icon: Icons.star_rounded,
                  label: 'Rating',
                  value: station.rating.toStringAsFixed(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: !_mapStation.isBookable
                ? null
                : () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => BookSlotScreen(
                          station: widget.partnerStation,
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.calendar_month_rounded),
            label: const Text('Book via Chargix'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
