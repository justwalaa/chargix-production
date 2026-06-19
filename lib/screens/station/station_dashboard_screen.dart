import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/chargix_data.dart';
import '../../models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../models/station_model.dart';
import '../../models/station_slot_model.dart';
import '../../utils/currency_format.dart';
import '../../utils/slot_availability.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import '../../widgets/chargix/settings_tile.dart';
import 'station_bookings_screen.dart';
import 'station_slots_screen.dart';

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

class StationDashboardScreen extends StatelessWidget {
  const StationDashboardScreen({super.key, required this.stationId});
  final String stationId;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _canvas,
      body: FirebaseStreamView<StationModel?>(
        stream: ChargixData.stationOwner.watchOwnedStation(stationId),
        emptyTitle: 'Station not found',
        emptyMessage: 'Complete registration or contact support.',
        emptyIcon: PhosphorIconsRegular.chargingStation,
        builder: (context, station) {
          if (station == null) return const SizedBox.shrink();

          return StreamBuilder<List<BookingModel>>(
            stream: ChargixData.stationOwner.watchStationBookings(stationId),
            builder: (context, bookingSnap) {
              final bookings = bookingSnap.data ?? const [];
              final today = DateTime.now();
              final pendingCount = bookings
                  .where((b) => b.status == BookingStatus.pending)
                  .length;
              final activeCount = bookings
                  .where((b) => b.status == BookingStatus.active)
                  .length;
              final todayCompleted = bookings.where((b) {
                if (b.status != BookingStatus.completed) return false;
                final s = b.scheduledStart;
                return s != null &&
                    s.year == today.year &&
                    s.month == today.month &&
                    s.day == today.day;
              }).length;

              return StreamBuilder<List<StationSlotModel>>(
            stream: ChargixData.stationOwner.watchSlots(stationId),
            builder: (context, slotSnap) {
              final slots = slotSnap.data ?? const [];
              final stats = SlotAvailability.compute(slots);

              return CustomScrollView(
                slivers: [
                  // ── Station hero ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      color: _white,
                      padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: _greenSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: _green.withValues(alpha: 0.3),
                                      width: 1.5),
                                ),
                                child: const Icon(PhosphorIconsFill.lightning,
                                    color: _greenDark, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(station.name,
                                        style: _sg(16, FontWeight.w800,
                                            ls: -0.3),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    Text(station.address,
                                        style: _dm(12, FontWeight.w400,
                                            color: _slate),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
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
                                            color: _green,
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 5),
                                    Text('Live',
                                        style: _dm(11, FontWeight.w700,
                                            color: _greenDark)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        16, 16, 16, 16 + bottomPad),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Metric cards ───────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: 'Available bays',
                                value:
                                    '${stats.driverVisible}/${stats.total}',
                                icon: PhosphorIconsRegular.chargingStation,
                                valueColor: stats.driverVisible > 0
                                    ? _green
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                label: 'Price / kWh',
                                value: CurrencyFormat.perKwh(
                                    station.pricePerKwh),
                                icon: PhosphorIconsRegular.currencyCircleDollar,
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 320.ms)
                            .slideY(begin: 0.06, end: 0, duration: 320.ms,
                                curve: Curves.easeOut),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: 'Pending',
                                value: '$pendingCount',
                                icon: PhosphorIconsRegular.clock,
                                valueColor: pendingCount > 0
                                    ? const Color(0xFFD97706)
                                    : _slate,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricCard(
                                label: 'Active now',
                                value: '$activeCount',
                                icon: PhosphorIconsFill.lightning,
                                valueColor: activeCount > 0 ? _green : _slate,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricCard(
                                label: "Today's done",
                                value: '$todayCompleted',
                                icon: PhosphorIconsRegular.checkCircle,
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 40.ms, duration: 320.ms)
                            .slideY(begin: 0.06, end: 0, delay: 40.ms,
                                duration: 320.ms, curve: Curves.easeOut),

                        if (stats.total > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${stats.open} open · ${stats.booked} occupied · '
                            '${stats.total - stats.open} closed',
                            style: _dm(12, FontWeight.w400, color: _slate),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // ── Quick actions ──────────────────────────────
                        Text('Quick actions',
                                style: _sg(13, FontWeight.w700,
                                    color: _slate, ls: 1.0))
                            .animate()
                            .fadeIn(delay: 60.ms, duration: 280.ms),
                        const SizedBox(height: 8),
                        _MenuCard(
                          tiles: [
                            SettingsTile(
                              icon: PhosphorIconsRegular.calendarCheck,
                              title: 'View all bookings',
                              subtitle: 'Approve, reject, start sessions',
                              onTap: () => Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => StationBookingsScreen(
                                      stationId: stationId),
                                ),
                              ),
                            ),
                            SettingsTile(
                              icon: PhosphorIconsRegular.plugsConnected,
                              title: 'Manage bays',
                              subtitle: 'Ports, pricing, availability',
                              onTap: () => Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => StationSlotsScreen(
                                      stationId: stationId),
                                ),
                              ),
                            ),
                            SettingsTile(
                              icon: PhosphorIconsRegular.gear,
                              title: 'Station settings',
                              subtitle: 'Hours, pricing, details',
                              onTap: () =>
                                  _comingSoon(context, 'Station settings'),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 80.ms, duration: 300.ms)
                            .slideY(begin: 0.05, end: 0, delay: 80.ms,
                                duration: 300.ms, curve: Curves.easeOut),

                        const SizedBox(height: 20),

                        // ── Operations ─────────────────────────────────
                        Text('Operations',
                                style: _sg(13, FontWeight.w700,
                                    color: _slate, ls: 1.0))
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 280.ms),
                        const SizedBox(height: 8),
                        _MenuCard(
                          tiles: [
                            SettingsTile(
                              icon: PhosphorIconsRegular.calendarCheck,
                              title: 'Booking approvals',
                              subtitle: 'Reservations & rejections',
                              onTap: () => Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => StationBookingsScreen(
                                      stationId: stationId),
                                ),
                              ),
                            ),
                            SettingsTile(
                              icon: PhosphorIconsRegular.plugsConnected,
                              title: 'Slot management',
                              subtitle: 'Ports, pricing, availability',
                              onTap: () => Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => StationSlotsScreen(
                                      stationId: stationId),
                                ),
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 120.ms, duration: 300.ms)
                            .slideY(begin: 0.05, end: 0, delay: 120.ms,
                                duration: 300.ms, curve: Curves.easeOut),

                        const SizedBox(height: 20),

                        // ── Insights ───────────────────────────────────
                        Text('Insights',
                                style: _sg(13, FontWeight.w700,
                                    color: _slate, ls: 1.0))
                            .animate()
                            .fadeIn(delay: 120.ms, duration: 280.ms),
                        const SizedBox(height: 8),
                        _MenuCard(
                          tiles: [
                            SettingsTile(
                              icon: PhosphorIconsRegular.clockCounterClockwise,
                              title: 'Booking history',
                              onTap: () => Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => StationBookingsScreen(
                                      stationId: stationId),
                                ),
                              ),
                            ),
                            SettingsTile(
                              icon: PhosphorIconsRegular.chartLineUp,
                              title: 'Earnings & statistics',
                              subtitle: 'Available after go-live',
                              onTap: () =>
                                  _comingSoon(context, 'Earnings'),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 140.ms, duration: 300.ms)
                            .slideY(begin: 0.05, end: 0, delay: 140.ms,
                                duration: 300.ms, curve: Curves.easeOut),

                        const SizedBox(height: 20),

                        // ── Operating hours ────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _greenSurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    PhosphorIconsRegular.clockAfternoon,
                                    size: 16,
                                    color: _greenDark),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Operating hours',
                                        style: _dm(11, FontWeight.w600,
                                            color: _slate)),
                                    Text(
                                      '${station.operatingHours.openTime} – '
                                      '${station.operatingHours.closeTime}'
                                      ' (${station.operatingHours.timezone})',
                                      style:
                                          _sg(13, FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 160.ms, duration: 280.ms),
                      ]),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
        },
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon.',
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white)),
        backgroundColor: _ink,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Metric card ───────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _green),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? _ink,
                  letterSpacing: -0.5)),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: _slate)),
        ],
      ),
    );
  }
}

// ── Menu card ─────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.tiles});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            for (int i = 0; i < tiles.length; i++) ...[
              tiles[i],
              if (i < tiles.length - 1)
                Divider(height: 1, color: _border, indent: 62),
            ],
          ],
        ),
      ),
    );
  }
}
