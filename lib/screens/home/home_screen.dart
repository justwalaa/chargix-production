import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/main_tab_scope.dart';
import '../../data/chargix_data.dart';
import '../../models/station_model.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/hero_header.dart';
import '../../widgets/home/quick_action_card.dart';
import '../stations/station_details_screen.dart';
import 'qr_scan_screen.dart';
import '../profile/charging_history_screen.dart';
import '../profile/favorites_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? 'Driver';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text(
              'Chargix',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                HeroHeader(
                  title: 'Ready to charge',
                  subtitle: phone,
                  icon: Icons.electric_car_rounded,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: const Text(
                      'EV',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Quick actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.map_rounded,
                        title: 'Find station',
                        onTap: () =>
                            MainTabScope.goTo(context, MainTabIndex.map),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Scan QR',
                        onTap: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const QrScanScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.ev_station_rounded,
                        title: 'Stations',
                        onTap: () =>
                            MainTabScope.goTo(context, MainTabIndex.stations),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.bookmark_rounded,
                        title: 'Saved',
                        onTap: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const FavoritesScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.bolt_rounded,
                        title: 'History',
                        onTap: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const ChargingHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'Bookings',
                        onTap: () =>
                            MainTabScope.goTo(context, MainTabIndex.bookings),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Recommended hub',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                StreamBuilder<List<StationModel>>(
                  stream: ChargixData.stations.watchMapPartnerStations(),
                  builder: (context, snapshot) {
                    final list = snapshot.data;
                    if (list == null || list.isEmpty) {
                      return Text(
                        'No partner hubs nearby yet — explore external chargers on the map.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      );
                    }
                    final station = list.first;
                    return _NearbyPickCard(
                      station: station,
                      onOpen: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => StationDetailsScreen(
                              partnerStation: station,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyPickCard extends StatelessWidget {
  const _NearbyPickCard({
    required this.station,
    required this.onOpen,
  });

  final StationModel station;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, color: scheme.primary, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      '${station.availablePorts} ports · ${station.pricePerKwh.toStringAsFixed(2)}/kWh · Partner',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
