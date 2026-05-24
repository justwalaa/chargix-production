import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/navigation/main_tab_scope.dart';
import '../../data/chargix_data.dart';
import '../../models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../models/map_station.dart';
import '../../services/map_stations_services.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens/tokens.dart';
import '../../utils/geo_utils.dart';
import '../../widgets/chargix/hero_header.dart';
import '../../widgets/chargix/premium_card.dart';
import '../../widgets/home/quick_action_card.dart';
import '../booking/booking_details_screen.dart';
import '../stations/station_details_screen.dart';
import 'qr_scan_screen.dart';
import '../profile/favorites_screen.dart';

/// Driver dashboard — nearby summary, recommendations, and quick actions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? _userLat;
  double? _userLng;
  List<MapStation> _nearby = [];
  StreamSubscription<List<MapStation>>? _stationsSub;

  @override
  void initState() {
    super.initState();
    _stationsSub =
        MapStationsService.instance.stationsStream.listen(_onStations);
    unawaited(_resolveLocation());
  }

  @override
  void dispose() {
    _stationsSub?.cancel();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });
      await MapStationsService.instance.load(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } on Object catch (_) {}
  }

  void _onStations(List<MapStation> list) {
    if (!mounted) return;
    var stations = list;
    if (_userLat != null && _userLng != null) {
      stations = list
          .map(
            (s) => s.copyWith(
              distanceKm: GeoUtils.distanceKm(
                _userLat!,
                _userLng!,
                s.latitude,
                s.longitude,
              ),
            ),
          )
          .toList()
        ..sort(
          (a, b) => (a.distanceKm ?? double.infinity)
              .compareTo(b.distanceKm ?? double.infinity),
        );
    }
    setState(() => _nearby = stations);
  }

  MapStation? get _recommended {
    final partners =
        _nearby.where((s) => s.isPartner && s.partner != null).toList();
    if (partners.isNotEmpty) return partners.first;
    if (_nearby.isNotEmpty) return _nearby.first;
    return null;
  }

  int get _partnerCount => _nearby.where((s) => s.isPartner).length;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final greetingName = user?.displayName ??
        user?.phoneNumber ??
        user?.email?.split('@').first ??
        'Driver';
    final scheme = Theme.of(context).colorScheme;
    final recommended = _recommended;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _resolveLocation,
        color: scheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    subtitle: greetingName,
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
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryStatCard(
                          label: 'Nearby',
                          value: _nearby.isEmpty
                              ? '—'
                              : '${_nearby.length}',
                          subtitle: _userLat != null
                              ? 'within ~10 km'
                              : 'Enable location',
                          accent: AppColors.neonGreen,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SummaryStatCard(
                          label: 'Chargix partners',
                          value: '$_partnerCount',
                          subtitle: 'book & track',
                          accent: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SessionStatusCard(uid: user?.uid),
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
                          title: 'Live map',
                          onTap: () =>
                              MainTabScope.goTo(context, MainTabIndex.map),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.bolt_rounded,
                          title: 'Quick match',
                          onTap: () {
                            MainTabScope.goTo(context, MainTabIndex.map);
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
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Recommended charger',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (recommended == null)
                    Text(
                      'Locating stations… Open the map to explore chargers near you.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    )
                  else
                    _RecommendedCard(
                      station: recommended,
                      onOpenMap: () =>
                          MainTabScope.goTo(context, MainTabIndex.map),
                      onOpenDetails: () {
                        final partner = recommended.partner?.station;
                        if (partner != null) {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => StationDetailsScreen(
                                partnerStation: partner,
                              ),
                            ),
                          );
                        } else {
                          MainTabScope.goTo(context, MainTabIndex.map);
                        }
                      },
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Recent activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RecentBookingsSection(uid: user?.uid),
                  const SizedBox(height: AppSpacing.xxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _SessionStatusCard extends StatelessWidget {
  const _SessionStatusCard({this.uid});

  final String? uid;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (uid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder(
      stream: ChargixData.bookings.watchBookingsForUser(uid!),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];
        final active = bookings.where((b) {
          return b.status == BookingStatus.confirmed ||
              b.status == BookingStatus.active;
        }).toList();

        if (active.isEmpty) {
          return PremiumCard(
            child: Row(
              children: [
                Icon(Icons.bolt_outlined, color: scheme.primary, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'No active charging session. Book a port at a Chargix partner.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          );
        }

        final booking = active.first;
        return PremiumCard(
          child: Row(
            children: [
              Icon(Icons.ev_station_rounded, color: scheme.primary, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming / active booking',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      'Station ${booking.stationId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  MainTabScope.goTo(context, MainTabIndex.activity);
                },
                child: const Text('View'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.station,
    required this.onOpenMap,
    required this.onOpenDetails,
  });

  final MapStation station;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final partner = station.partner?.station;
    final dist = GeoUtils.formatDistanceKm(station.distanceKm);

    return PremiumCard(
      onTap: onOpenDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                station.isPartner ? Icons.verified_rounded : Icons.public_rounded,
                color: scheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  station.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                dist,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            station.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          if (partner != null) ...[
            const SizedBox(height: 8),
            Text(
              '${partner.availablePorts}/${partner.totalPorts} ports · '
              '${partner.pricePerKwh.toStringAsFixed(2)}/kWh',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenMap,
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text('Map'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenDetails,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(station.isPartner ? 'Details' : 'Navigate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentBookingsSection extends StatelessWidget {
  const _RecentBookingsSection({this.uid});

  final String? uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return Text(
        'Sign in to see recent bookings.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return StreamBuilder<List<BookingModel>>(
      stream: ChargixData.bookings.watchBookingsForUser(uid!),
      builder: (context, snapshot) {
        final list = snapshot.data;
        if (list == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (list.isEmpty) {
          return Text(
            'No bookings yet — reserve from the map or a partner station.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          );
        }

        final recent = list.take(3).toList();
        return Column(
          children: [
            for (final booking in recent) ...[
              PremiumCard(
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => BookingDetailsScreen(booking: booking),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Station ${booking.stationId}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            booking.status.value,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    MainTabScope.goTo(context, MainTabIndex.activity),
                child: const Text('All activity →'),
              ),
            ),
          ],
        );
      },
    );
  }
}
