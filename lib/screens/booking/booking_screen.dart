import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/navigation/main_tab_scope.dart';
import '../../data/chargix_data.dart';
import '../../models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import 'booking_details_screen.dart';

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
    {Color color = _ink, double ls = 0}) =>
    GoogleFonts.spaceGrotesk(
        fontSize: size, fontWeight: w, color: color, letterSpacing: ls);

TextStyle _dm(double size, FontWeight w, {Color color = _ink, double? h}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color, height: h);

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final topPad = MediaQuery.paddingOf(context).top;

    if (uid == null) {
      return Scaffold(
        backgroundColor: _canvas,
        body: Column(
          children: [
            _Header(topPad: topPad),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                            color: _greenSurface, shape: BoxShape.circle),
                        child: const Icon(PhosphorIconsRegular.lockSimple,
                            color: _green, size: 32),
                      ),
                      const SizedBox(height: 20),
                      Text('Sign in required',
                          style: _sg(18, FontWeight.w800, ls: -0.3)),
                      const SizedBox(height: 8),
                      Text(
                        'Log in with your phone number to view reservations.',
                        textAlign: TextAlign.center,
                        style: _dm(14, FontWeight.w400, color: _slate, h: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _canvas,
      body: Column(
        children: [
          _Header(topPad: topPad),
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: ChargixData.bookings.watchBookingsForUser(uid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, _) => _ShimmerTile(),
                  );
                }

                final bookings = snap.data!;
                if (bookings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                                color: _greenSurface,
                                shape: BoxShape.circle),
                            child: const Icon(
                                PhosphorIconsRegular.calendarBlank,
                                color: _green,
                                size: 32),
                          ),
                          const SizedBox(height: 20),
                          Text('No bookings yet',
                              style: _sg(18, FontWeight.w800, ls: -0.3)),
                          const SizedBox(height: 8),
                          Text(
                            'Reserve a charger from Stations or Map to track sessions here.',
                            textAlign: TextAlign.center,
                            style: _dm(14, FontWeight.w400,
                                color: _slate, h: 1.5),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () => MainTabScope.goTo(
                                context, MainTabIndex.map),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: _green,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _green.withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Text('Browse stations',
                                  style: _sg(14, FontWeight.w700,
                                      color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: _green,
                  backgroundColor: _white,
                  onRefresh: () async {},
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      return _BookingTile(
                        booking: bookings[i],
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                BookingDetailsScreen(booking: bookings[i]),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: (60 * i).ms, duration: 280.ms)
                          .slideY(
                              begin: 0.06,
                              end: 0,
                              delay: (60 * i).ms,
                              duration: 280.ms,
                              curve: Curves.easeOut);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.topPad});
  final double topPad;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _white,
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 14),
      child: Row(
        children: [
          const Icon(PhosphorIconsFill.calendarCheck,
              color: _green, size: 22),
          const SizedBox(width: 10),
          Text('My Bookings',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.4)),
        ],
      ),
    );
  }
}

// ── Booking tile ──────────────────────────────────────────────────────────────
class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking, required this.onTap});
  final BookingModel booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = booking.scheduledStart;
    final dateStr = start != null
        ? '${start.day}/${start.month}/${start.year}  ${start.hour}:${start.minute.toString().padLeft(2, '0')}'
        : 'Station ${booking.stationId}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _white,
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _greenSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(PhosphorIconsFill.lightning,
                  color: _greenDark, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reservation ${booking.id.length > 8 ? booking.id.substring(0, 8) : booking.id}',
                    style: _sg(13, FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(dateStr,
                      style: _dm(12, FontWeight.w400, color: _slate)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _StatusPill(status: booking.status),
            const SizedBox(width: 6),
            const Icon(PhosphorIconsRegular.caretRight,
                size: 14, color: _slate),
          ],
        ),
      ),
    );
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case BookingStatus.confirmed:
      case BookingStatus.active:
        bg = _greenSurface;
        fg = _greenDark;
      case BookingStatus.cancelled:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
      case BookingStatus.pending:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
      default:
        bg = const Color(0xFFF3F4F6);
        fg = _slate;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.value.toUpperCase(),
        style: GoogleFonts.dmSans(
            fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ── Shimmer tile ──────────────────────────────────────────────────────────────
class _ShimmerTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1400.ms, color: const Color(0xFFE5E7EB));
  }
}
