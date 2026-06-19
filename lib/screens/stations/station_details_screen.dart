import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/chargix_data.dart';
import '../../models/station_model.dart';
import '../booking/book_slot_screen.dart';
import '../../models/map_station.dart';
import '../../utils/map_station_mapper.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const _green        = Color(0xFF22C55E);
const _greenDark    = Color(0xFF16A34A);
const _greenSurface = Color(0xFFDCFCE7);
const _canvas       = Color(0xFFF8F9FA);
const _white        = Color(0xFFFFFFFF);
const _ink          = Color(0xFF101828);
const _slate        = Color(0xFF6B7280);
const _border       = Color(0xFFE5E7EB);

TextStyle _sg(double size, FontWeight w,
    {Color color = _ink, double ls = 0, double? height}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size, fontWeight: w, color: color,
        letterSpacing: ls, height: height);

TextStyle _dm(double size, FontWeight w,
    {Color color = _ink, double? height}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color, height: height);

/// Partner station details — booking enabled (Chargix Firestore only).
class StationDetailsScreen extends StatefulWidget {
  const StationDetailsScreen({super.key, required this.partnerStation});
  final StationModel partnerStation;

  @override
  State<StationDetailsScreen> createState() => _StationDetailsScreenState();
}

class _StationDetailsScreenState extends State<StationDetailsScreen> {
  MapStation get _mapStation =>
      MapStationMapper.fromPartner(widget.partnerStation);

  bool _isFav = false;
  bool _favLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavState();
  }

  Future<void> _loadFavState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    ChargixData.favorites
        .watchFavoriteStationIds(uid)
        .listen((ids) {
      if (mounted) {
        setState(() => _isFav = ids.contains(widget.partnerStation.id));
      }
    });
  }

  Future<void> _toggleFav() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _favLoading = true);
    await ChargixData.favorites.toggleFavorite(
      userId: uid,
      stationId: widget.partnerStation.id,
      add: !_isFav,
    );
    if (mounted) setState(() => _favLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final station = widget.partnerStation;
    final isBookable = _mapStation.isBookable;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _canvas,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Collapsing hero header ───────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: _white,
                foregroundColor: _ink,
                elevation: 0,
                scrolledUnderElevation: 0.5,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: _favLoading ? null : _toggleFav,
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: EdgeInsets.only(
                            top: topPad > 20 ? 8 : 4),
                        decoration: BoxDecoration(
                          color: _isFav ? const Color(0xFFDCFCE7) : _white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isFav
                                ? _green.withValues(alpha: 0.4)
                                : _border,
                          ),
                        ),
                        child: _favLoading
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: _green),
                              )
                            : Icon(
                                _isFav
                                    ? PhosphorIconsFill.bookmarkSimple
                                    : PhosphorIconsRegular.bookmarkSimple,
                                size: 17,
                                color: _isFav ? _green : _slate,
                              ),
                      ),
                    ),
                  ),
                ],
                leading: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: EdgeInsets.fromLTRB(12, topPad > 20 ? 8 : 4, 0, 0),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(PhosphorIconsRegular.arrowLeft,
                        color: _ink, size: 18),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: _HeroHeader(station: station),
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // Station name + address block
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(station.name,
                                style: _sg(22, FontWeight.w800, ls: -0.4))
                            .animate()
                            .fadeIn(duration: 350.ms)
                            .slideY(begin: 0.08, end: 0, duration: 350.ms,
                                curve: Curves.easeOut),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(PhosphorIconsRegular.mapPin,
                                size: 13, color: _slate),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(station.address,
                                      style: _dm(13, FontWeight.w400,
                                          color: _slate))
                                  .animate()
                                  .fadeIn(delay: 40.ms, duration: 340.ms),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      children: [
                        _StatPill(
                          icon: PhosphorIconsRegular.plug,
                          label: '${station.availablePorts} of '
                              '${station.totalPorts} ports',
                          color: station.availablePorts > 0
                              ? _green
                              : const Color(0xFFEF4444),
                          bg: station.availablePorts > 0
                              ? _greenSurface
                              : const Color(0xFFFEE2E2),
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          icon: PhosphorIconsRegular.star,
                          label: station.rating.toStringAsFixed(1),
                          color: const Color(0xFFD97706),
                          bg: const Color(0xFFFEF3C7),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 80.ms, duration: 340.ms),

                    const SizedBox(height: 24),

                    // Details card
                    _DetailsCard(station: station)
                        .animate()
                        .fadeIn(delay: 120.ms, duration: 360.ms)
                        .slideY(begin: 0.06, end: 0, delay: 120.ms,
                            duration: 360.ms, curve: Curves.easeOut),
                  ]),
                ),
              ),
            ],
          ),

          // ── Book button pinned at bottom ───────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPad),
              decoration: BoxDecoration(
                color: _white,
                border: Border(top: BorderSide(color: _border, width: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: _BookButton(
                isBookable: isBookable,
                onTap: isBookable
                    ? () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                BookSlotScreen(station: widget.partnerStation),
                          ),
                        )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero header (collapsible) ─────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.station});
  final StationModel station;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _greenSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _green.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(PhosphorIconsFill.lightning,
                    color: _greenDark, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                'Chargix Partner',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _greenDark,
                    letterSpacing: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat pill ─────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── Details card ──────────────────────────────────────────────────────────────
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.station});
  final StationModel station;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: PhosphorIconsRegular.chargingStation,
            label: 'Availability',
            value: '${station.availablePorts} of ${station.totalPorts}'
                ' ports open',
            valueColor: station.availablePorts > 0 ? _green : null,
          ),
          Divider(height: 1, color: _border),
          _DetailRow(
            icon: PhosphorIconsRegular.currencyCircleDollar,
            label: 'Price',
            value: '${station.pricePerKwh.toStringAsFixed(3)} JOD / kWh',
          ),
          Divider(height: 1, color: _border),
          _DetailRow(
            icon: PhosphorIconsRegular.star,
            label: 'Rating',
            value: '${station.rating.toStringAsFixed(1)} / 5.0',
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
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _greenSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: _greenDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _slate)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: valueColor ?? _ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Book button ───────────────────────────────────────────────────────────────
class _BookButton extends StatelessWidget {
  const _BookButton({required this.isBookable, required this.onTap});
  final bool isBookable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isBookable ? _green : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isBookable
              ? [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.32),
                    blurRadius: 18,
                    spreadRadius: -4,
                    offset: const Offset(0, 7),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.calendarCheck,
                color: isBookable ? Colors.white : _slate, size: 20),
            const SizedBox(width: 10),
            Text(
              isBookable ? 'Book via Chargix' : 'Booking unavailable',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isBookable ? Colors.white : _slate,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
