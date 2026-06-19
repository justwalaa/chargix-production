import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/navigation/main_tab_scope.dart';
import '../../data/chargix_data.dart';
import '../../models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../models/map_station.dart';
import '../../core/config/maps_config.dart';
import '../../services/stations_map_service.dart';
import '../../utils/geo_utils.dart';
import '../booking/booking_details_screen.dart';
import '../notifications_screen.dart';
import '../stations/station_details_screen.dart';
import 'qr_scan_screen.dart';
import '../profile/favorites_screen.dart';

// ── Design tokens (light / green system) ────────────────────────────────────
const _green        = Color(0xFF22C55E);
const _greenDark    = Color(0xFF16A34A);
const _greenSurface = Color(0xFFDCFCE7);
const _canvas       = Color(0xFFF8F9FA);
const _white        = Color(0xFFFFFFFF);
const _ink          = Color(0xFF101828);
const _slate        = Color(0xFF6B7280);
const _border       = Color(0xFFE5E7EB);
const _cardBg       = Color(0xFFFFFFFF);

// ── Typography helpers ───────────────────────────────────────────────────────
TextStyle _sg(double size, FontWeight weight,
    {Color color = _ink, double letterSpacing = 0, double? height}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

TextStyle _dm(double size, FontWeight weight,
    {Color color = _ink, double? height, double letterSpacing = 0}) =>
    GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

// ── Driver dashboard ─────────────────────────────────────────────────────────
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
    var lat = MapsConfig.fallbackLatitude;
    var lng = MapsConfig.fallbackLongitude;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium),
        ).timeout(const Duration(seconds: 12));
        lat = pos.latitude;
        lng = pos.longitude;
        if (mounted) setState(() { _userLat = lat; _userLng = lng; });
      }
    } on Object catch (_) {}
    await MapStationsService.instance.load(latitude: lat, longitude: lng);
  }

  void _onStations(List<MapStation> list) {
    if (!mounted) return;
    var stations = list;
    if (_userLat != null && _userLng != null) {
      stations = list
          .map((s) => s.copyWith(
                distanceKm: GeoUtils.distanceKm(
                    _userLat!, _userLng!, s.latitude, s.longitude),
              ))
          .toList()
        ..sort((a, b) => (a.distanceKm ?? double.infinity)
            .compareTo(b.distanceKm ?? double.infinity));
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = user?.displayName?.split(' ').first ??
        user?.phoneNumber ??
        user?.email?.split('@').first ??
        'Driver';
    final uid = user?.uid;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _canvas,
      body: RefreshIndicator(
        onRefresh: _resolveLocation,
        color: _green,
        backgroundColor: _white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Greeting bar ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, topPad + 20, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(),
                            style: _dm(13, FontWeight.w500, color: _slate)),
                        const SizedBox(height: 1),
                        Text(firstName,
                            style: _sg(26, FontWeight.w800,
                                letterSpacing: -0.5)),
                      ],
                    ),
                    const Spacer(),
                    _CircleBtn(
                      icon: PhosphorIconsRegular.bell,
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 380.ms)
                  .slideY(begin: -0.12, end: 0, duration: 380.ms,
                      curve: Curves.easeOut),
            ),

            // ── EV hero — car floats directly on canvas ───────────────────
            SliverToBoxAdapter(
              child: _VehicleSection(
                nearby: _nearby,
                userLat: _userLat,
              )
                  .animate()
                  .fadeIn(delay: 60.ms, duration: 480.ms)
                  .slideY(begin: 0.06, end: 0, delay: 60.ms, duration: 480.ms,
                      curve: Curves.easeOut),
            ),

            // ── Stat pills ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Nearby',
                        value: _nearby.isEmpty ? '—' : '${_nearby.length}',
                        sub: _userLat != null
                            ? 'within ~25 km'
                            : 'Enable location',
                        icon: PhosphorIconsRegular.mapPin,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Partners',
                        value: '$_partnerCount',
                        sub: 'book & track',
                        icon: PhosphorIconsFill.checkCircle,
                        iconColor: _green,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 140.ms, duration: 420.ms)
                  .slideY(begin: 0.08, end: 0, delay: 140.ms, duration: 420.ms,
                      curve: Curves.easeOut),
            ),

            // ── Quick actions ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick actions',
                        style: _sg(16, FontWeight.w700, letterSpacing: -0.2)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickTile(
                            icon: PhosphorIconsRegular.mapTrifold,
                            label: 'Live map',
                            onTap: () =>
                                MainTabScope.goTo(context, MainTabIndex.map),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickTile(
                            icon: PhosphorIconsRegular.lightning,
                            label: 'Quick match',
                            accent: true,
                            onTap: () =>
                                MainTabScope.goTo(context, MainTabIndex.map),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickTile(
                            icon: PhosphorIconsRegular.qrCode,
                            label: 'Scan QR',
                            onTap: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                    builder: (_) => const QrScanScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickTile(
                            icon: PhosphorIconsRegular.bookmarkSimple,
                            label: 'Saved',
                            onTap: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                    builder: (_) => const FavoritesScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 420.ms)
                  .slideY(begin: 0.08, end: 0, delay: 200.ms, duration: 420.ms,
                      curve: Curves.easeOut),
            ),

            // ── Active booking banner ──────────────────────────────────────
            if (uid != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: _ActiveBanner(uid: uid),
                ).animate().fadeIn(delay: 260.ms, duration: 380.ms),
              ),

            // ── Nearest charger ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nearest charger',
                        style: _sg(16, FontWeight.w700, letterSpacing: -0.2)),
                    const SizedBox(height: 12),
                    _NearestCard(
                      station: _recommended,
                      loading: _nearby.isEmpty,
                      onOpenMap: () =>
                          MainTabScope.goTo(context, MainTabIndex.map),
                      onOpenDetails: () {
                        final rec = _recommended;
                        final partner = rec?.partner?.station;
                        if (partner != null) {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  StationDetailsScreen(partnerStation: partner),
                            ),
                          );
                        } else {
                          MainTabScope.goTo(context, MainTabIndex.map);
                        }
                      },
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 420.ms)
                  .slideY(begin: 0.08, end: 0, delay: 300.ms, duration: 420.ms,
                      curve: Curves.easeOut),
            ),

            // ── Recent activity ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Recent activity',
                            style: _sg(16, FontWeight.w700,
                                letterSpacing: -0.2)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => MainTabScope.goTo(
                              context, MainTabIndex.activity),
                          child: Text('All →',
                              style: _dm(13, FontWeight.w600, color: _green)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (uid == null)
                      _EmptyCard(
                          icon: PhosphorIconsRegular.calendar,
                          message: 'Sign in to see your bookings.')
                    else
                      _RecentActivity(uid: uid),
                  ],
                ),
              ).animate().fadeIn(delay: 360.ms, duration: 400.ms),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 40 + bottomPad)),
          ],
        ),
      ),
    );
  }
}

// ── EV hero — car floats on canvas, no container ──────────────────────────────

class _VehicleSection extends StatelessWidget {
  const _VehicleSection({required this.nearby, required this.userLat});
  final List<MapStation> nearby;
  final double? userLat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('YOUR ELECTRIC VEHICLE',
                  style: _dm(10, FontWeight.w700,
                      color: _slate, letterSpacing: 1.2)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _greenSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: _green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text('Ready',
                        style:
                            _dm(11, FontWeight.w600, color: _greenDark)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Car image — no container, floats directly on the canvas
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Image.asset(
            'assets/images/ev_car.png',
            height: 172,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const SizedBox(height: 172),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          child: Text(
            userLat != null
                ? '${nearby.isNotEmpty ? nearby.length : "—"} EV chargers found nearby'
                : 'Enable location to find chargers near you',
            style: _dm(12, FontWeight.w400, color: _slate),
          ),
        ),
      ],
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    this.iconColor = _slate,
  });

  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Text(label, style: _dm(11, FontWeight.w500, color: _slate)),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (_, t, child) => Opacity(opacity: t, child: child),
            child: Text(value,
                style: _sg(30, FontWeight.w800,
                    letterSpacing: -0.8, height: 1.0)),
          ),
          const SizedBox(height: 2),
          Text(sub, style: _dm(11, FontWeight.w400, color: _slate)),
        ],
      ),
    );
  }
}

// ── Quick action tile ─────────────────────────────────────────────────────────

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final bg = accent ? _green : _cardBg;
    final fg = accent ? Colors.white : _ink;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: accent ? null : Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: accent
                  ? _green.withValues(alpha: 0.28)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: accent ? 14 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: fg),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: _dm(10, FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}

// ── Active booking banner ─────────────────────────────────────────────────────

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingModel>>(
      stream: ChargixData.bookings.watchBookingsForUser(uid),
      builder: (ctx, snap) {
        final active = (snap.data ?? [])
            .where((b) =>
                b.status == BookingStatus.confirmed ||
                b.status == BookingStatus.active)
            .toList();
        if (active.isEmpty) return const SizedBox.shrink();
        final booking = active.first;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _greenDark,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _greenDark.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(PhosphorIconsFill.lightning,
                  color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active booking',
                        style: _sg(13, FontWeight.w700, color: Colors.white)),
                    Text('Station ${booking.stationId}',
                        style: _dm(11, FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () =>
                    MainTabScope.goTo(context, MainTabIndex.activity),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('View',
                      style: _dm(12, FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Nearest charger card ──────────────────────────────────────────────────────

class _NearestCard extends StatelessWidget {
  const _NearestCard({
    required this.station,
    required this.loading,
    required this.onOpenMap,
    required this.onOpenDetails,
  });

  final MapStation? station;
  final bool loading;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    if (loading) return _shimmerCard();

    if (station == null) {
      return _EmptyCard(
        icon: PhosphorIconsRegular.mapPinLine,
        message: 'Locating stations… Open the map to explore chargers near you.',
      );
    }

    final partner = station!.partner?.station;
    final dist = GeoUtils.formatDistanceKm(station!.distanceKm);
    final ports = partner != null
        ? '${partner.availablePorts}/${partner.totalPorts} ports'
        : null;

    return GestureDetector(
      onTap: onOpenDetails,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: station!.isPartner
                        ? _greenSurface
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    station!.isPartner
                        ? PhosphorIconsFill.checkCircle
                        : PhosphorIconsRegular.mapPin,
                    size: 20,
                    color: station!.isPartner ? _green : _slate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _sg(14, FontWeight.w700),
                      ),
                      Text(
                        station!.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _dm(12, FontWeight.w400, color: _slate),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(dist,
                        style: _sg(14, FontWeight.w700, color: _green)),
                    if (ports != null)
                      Text(ports,
                          style: _dm(11, FontWeight.w400, color: _slate)),
                  ],
                ),
              ],
            ),
            if (partner != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.plug,
                        size: 13, color: _slate),
                    const SizedBox(width: 6),
                    Text(
                      '${partner.pricePerKwh.toStringAsFixed(2)} JOD/kWh',
                      style: _dm(12, FontWeight.w500, color: _slate),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: partner.availablePorts > 0
                            ? _greenSurface
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        partner.availablePorts > 0
                            ? '${partner.availablePorts} available'
                            : 'All occupied',
                        style: _dm(
                          10,
                          FontWeight.w600,
                          color: partner.availablePorts > 0
                              ? _greenDark
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _OutlineBtn(label: 'Open map', onTap: onOpenMap)),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilledBtn(
                    label: station!.isPartner ? 'Details' : 'Navigate',
                    onTap: onOpenDetails,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerCard() {
    return Container(
      height: 128,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _ShimmerBox(width: 44, height: 44, radius: 12),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: 140, height: 14),
                  SizedBox(height: 6),
                  _ShimmerBox(width: 100, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _ShimmerBox(width: double.infinity, height: 36, radius: 10),
        ],
      ),
    );
  }
}

// ── Recent activity ───────────────────────────────────────────────────────────

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingModel>>(
      stream: ChargixData.bookings.watchBookingsForUser(uid),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Column(
            children: [
              _ShimmerBox(height: 64, radius: 12),
              SizedBox(height: 8),
              _ShimmerBox(height: 64, radius: 12),
            ],
          );
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return _EmptyCard(
            icon: PhosphorIconsRegular.calendar,
            message:
                'No bookings yet — reserve from the map or a partner station.',
          );
        }
        final recent = list.take(3).toList();
        return Column(
          children: [
            for (int i = 0; i < recent.length; i++) ...[
              _BookingRow(booking: recent[i])
                  .animate()
                  .fadeIn(delay: (80 * i).ms, duration: 280.ms),
              if (i < recent.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking});
  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => BookingDetailsScreen(booking: booking),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(PhosphorIconsRegular.lightning,
                  size: 16, color: _slate),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Station ${booking.stationId}',
                      style: _sg(13, FontWeight.w600)),
                  Text(booking.status.value,
                      style: _dm(11, FontWeight.w400, color: _slate)),
                ],
              ),
            ),
            const Icon(PhosphorIconsRegular.caretRight,
                size: 16, color: _slate),
          ],
        ),
      ),
    );
  }
}

// ── Empty state card ──────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _slate),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: _dm(12, FontWeight.w400, color: _slate, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer loading box ───────────────────────────────────────────────────────

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          color: Colors.white.withValues(alpha: 0.65),
        );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border, width: 1.5),
        ),
        child: Text(label, style: _dm(13, FontWeight.w600)),
      ),
    );
  }
}

class _FilledBtn extends StatelessWidget {
  const _FilledBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(label,
            style: _dm(13, FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}

// ── Circle icon button ────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: _ink),
      ),
    );
  }
}
