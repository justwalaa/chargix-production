import 'package:flutter/material.dart';

import '../../data/chargix_data.dart';
import '../../models/station_model.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import '../../widgets/chargix/hero_header.dart';
import '../../widgets/chargix/premium_card.dart';
import '../../widgets/chargix/settings_tile.dart';
import 'station_bookings_screen.dart';
import 'station_slots_screen.dart';

class StationDashboardScreen extends StatelessWidget {
  const StationDashboardScreen({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operator dashboard')),
      body: FirebaseStreamView<StationModel?>(
        stream: ChargixData.stationOwner.watchOwnedStation(stationId),
        emptyTitle: 'Station not found',
        emptyMessage: 'Complete registration or contact support.',
        builder: (context, station) {
          if (station == null) {
            return const SizedBox.shrink();
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            children: [
              if (!station.status.isPublicOnMap)
                PremiumCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          station.status.isPendingApproval
                              ? 'Pending approval — not visible on the public map yet.'
                              : 'Station not live. Contact Chargix support.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!station.status.isPublicOnMap)
                const SizedBox(height: AppSpacing.md),
              HeroHeader(
                title: station.name,
                subtitle: station.address,
                icon: Icons.storefront_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Open ports',
                      value: '${station.availablePorts}/${station.totalPorts}',
                      icon: Icons.ev_station_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MetricCard(
                      label: 'Price / kWh',
                      value: '\$${station.pricePerKwh.toStringAsFixed(2)}',
                      icon: Icons.payments_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Operations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PremiumCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.inbox_rounded,
                      title: 'Booking approvals',
                      subtitle: 'Reservations & rejections',
                      onTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                StationBookingsScreen(stationId: stationId),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.grid_view_rounded,
                      title: 'Slot management',
                      subtitle: 'Ports, pricing, availability',
                      onTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                StationSlotsScreen(stationId: stationId),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.directions_bus_rounded,
                      title: 'Fleet & buses',
                      subtitle: 'Post-approval module',
                      onTap: () => _comingSoon(context, 'Fleet management'),
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.route_rounded,
                      title: 'Trips & schedules',
                      subtitle: 'Post-approval module',
                      onTap: () => _comingSoon(context, 'Trip planning'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PremiumCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.history_rounded,
                      title: 'Booking history',
                      onTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                StationBookingsScreen(stationId: stationId),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SettingsTile(
                      icon: Icons.insights_rounded,
                      title: 'Earnings & statistics',
                      subtitle: 'Available after go-live',
                      onTap: () => _comingSoon(context, 'Earnings dashboard'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operating hours',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${station.operatingHours.openTime} – ${station.operatingHours.closeTime} (${station.operatingHours.timezone})',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature unlocks after station approval.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
