import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/chargix_data.dart';
import '../../models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import '../../widgets/chargix/firebase_stream_view.dart';

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

class StationBookingsScreen extends StatelessWidget {
  const StationBookingsScreen({super.key, required this.stationId});
  final String stationId;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _canvas,
      body: Column(
        children: [
          Container(
            color: _white,
            padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.arrowLeft,
                      color: _ink, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text('Reservations', style: _sg(17, FontWeight.w700)),
                ),
              ],
            ),
          ),
          Container(height: 0.8, color: _border),
          Expanded(
            child: FirebaseStreamView<List<BookingModel>>(
              stream:
                  ChargixData.stationOwner.watchStationBookings(stationId),
              emptyIcon: PhosphorIconsRegular.calendarBlank,
              emptyTitle: 'No reservations',
              emptyMessage:
                  'Incoming EV and shipment bookings will appear here.',
              builder: (context, bookings) {
                // Pending first, then rest sorted by scheduled start desc
                final pending = bookings
                    .where((b) => b.status == BookingStatus.pending)
                    .toList();
                final others = bookings
                    .where((b) => b.status != BookingStatus.pending)
                    .toList()
                  ..sort((a, b) => (b.scheduledStart ?? DateTime(0))
                      .compareTo(a.scheduledStart ?? DateTime(0)));

                // Build a flat list: optional pending header + pending items +
                // optional others header + other items.
                // We encode sections as a sealed union using a simple type.
                final items = <Object>[
                  if (pending.isNotEmpty)
                    _SectionHeader('Pending (${pending.length})'),
                  ...pending,
                  if (others.isNotEmpty)
                    _SectionHeader(pending.isEmpty ? 'All' : 'Earlier'),
                  ...others,
                ];

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, i) {
                    final item = items[i];
                    if (item is _SectionHeader) return const SizedBox.shrink();
                    return const SizedBox(height: 10);
                  },
                  itemBuilder: (context, i) {
                    final item = items[i];
                    if (item is _SectionHeader) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          item.label.toUpperCase(),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _slate,
                            letterSpacing: 1.1,
                          ),
                        ),
                      );
                    }
                    final booking = item as BookingModel;
                    return _BookingCard(
                      booking: booking,
                      onRespond: (status) =>
                          _respond(context, booking, status),
                      onShowQr: () =>
                          _showQrDialog(context, booking),
                    )
                        .animate()
                        .fadeIn(delay: (50 * i).ms, duration: 260.ms)
                        .slideY(
                            begin: 0.05,
                            end: 0,
                            delay: (50 * i).ms,
                            duration: 260.ms,
                            curve: Curves.easeOut);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showQrDialog(
      BuildContext context, BookingModel booking) async {
    final slotId = booking.slotId ?? '';
    final qrData =
        'chargix://station/$stationId/bay/$slotId/booking/${booking.id}';
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _greenSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(PhosphorIconsRegular.qrCode,
                      color: _greenDark, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Show this QR to the driver',
                          style: _sg(15, FontWeight.w800)),
                      Text('Driver scans to begin charging',
                          style: _dm(12, FontWeight.w400, color: _slate)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: _white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bay: ${slotId.isNotEmpty ? slotId : "N/A"}',
                style: _dm(12, FontWeight.w400, color: _slate),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Close',
                      style: _sg(14, FontWeight.w600, color: _ink)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _respond(
    BuildContext context,
    BookingModel booking,
    BookingStatus status,
  ) async {
    final result = await ChargixData.stationOwner.respondToBooking(
      booking: booking,
      status: status,
      rejectionReason:
          status == BookingStatus.rejected ? 'Unavailable slot' : null,
    );
    if (!context.mounted) return;
    final ok = result.isSuccess;
    final message = !ok
        ? 'Update failed'
        : switch (status) {
            BookingStatus.approved ||
            BookingStatus.confirmed =>
              'Booking confirmed — driver notified',
            BookingStatus.rejected =>
              'Booking rejected — driver notified',
            BookingStatus.active => 'Charging session started',
            BookingStatus.completed => 'Session marked complete',
            _ => 'Booking updated',
          };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: _dm(13, FontWeight.w500, color: Colors.white)),
        backgroundColor: ok ? _greenDark : _ink,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Section header marker (used in the mixed list) ───────────────────────────
class _SectionHeader {
  const _SectionHeader(this.label);
  final String label;
}

// ── Booking card ──────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onRespond,
    required this.onShowQr,
  });

  final BookingModel booking;
  final void Function(BookingStatus) onRespond;
  final VoidCallback onShowQr;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final start = b.scheduledStart;
    final dateStr = start != null
        ? '${start.day}/${start.month}/${start.year}  '
          '${start.hour.toString().padLeft(2, '0')}:'
          '${start.minute.toString().padLeft(2, '0')}'
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _greenSurface,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(PhosphorIconsFill.lightning,
                    color: _greenDark, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Booking ${b.id.substring(0, b.id.length.clamp(0, 8))}',
                            style: _sg(13, FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (b.isDriverVerified == true) ...[
                          const SizedBox(width: 5),
                          const Icon(PhosphorIconsFill.sealCheck,
                              size: 13, color: _greenDark),
                        ],
                      ],
                    ),
                    if (dateStr != null)
                      Text(dateStr,
                          style: _dm(11, FontWeight.w400, color: _slate)),
                  ],
                ),
              ),
              _StatusPill(status: b.status),
            ],
          ),

          // Action buttons
          if (b.status == BookingStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'Reject',
                    onTap: () => onRespond(BookingStatus.rejected),
                    style: _BtnStyle.outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    label: 'Accept',
                    onTap: () => onRespond(BookingStatus.approved),
                    style: _BtnStyle.filled,
                  ),
                ),
              ],
            ),
          ],

          if (b.status == BookingStatus.approved) ...[
            const SizedBox(height: 12),
            _ActionBtn(
              label: 'Show QR to driver',
              icon: PhosphorIconsRegular.qrCode,
              onTap: onShowQr,
              style: _BtnStyle.filled,
              fullWidth: true,
            ),
          ],

          if (b.status == BookingStatus.active) ...[
            const SizedBox(height: 12),
            _ActionBtn(
              label: 'Mark completed',
              icon: PhosphorIconsRegular.checkCircle,
              onTap: () => onRespond(BookingStatus.completed),
              style: _BtnStyle.tonal,
              fullWidth: true,
            ),
          ],
        ],
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
    Color bg = const Color(0xFFF3F4F6);
    Color fg = _slate;
    switch (status) {
      case BookingStatus.approved:
      case BookingStatus.confirmed:
      case BookingStatus.active:
      case BookingStatus.completed:
        bg = _greenSurface;
        fg = _greenDark;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
      case BookingStatus.pending:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.value.toUpperCase(),
        style: GoogleFonts.dmSans(
            fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────
enum _BtnStyle { filled, outline, tonal }

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.onTap,
    required this.style,
    this.icon,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback onTap;
  final _BtnStyle style;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color? borderColor;

    switch (style) {
      case _BtnStyle.filled:
        bg = _green;
        fg = Colors.white;
      case _BtnStyle.outline:
        bg = Colors.transparent;
        fg = const Color(0xFFDC2626);
        borderColor = const Color(0xFFDC2626).withValues(alpha: 0.4);
      case _BtnStyle.tonal:
        bg = _greenSurface;
        fg = _greenDark;
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: fg, size: 16),
          const SizedBox(width: 6),
        ],
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg)),
      ],
    );

    Widget btn = GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1.5)
              : null,
          boxShadow: style == _BtnStyle.filled
              ? [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
