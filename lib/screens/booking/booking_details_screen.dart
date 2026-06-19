import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/chargix_data.dart';
import '../../models/booking_model.dart';
import '../../models/enums/booking_status.dart';
import 'booking_qr_scan_screen.dart';

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

TextStyle _dm(double size, FontWeight w,
    {Color color = _ink, double? h}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color, height: h);

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({
    super.key,
    required this.booking,
    this.stationName,
  });

  final BookingModel booking;
  final String? stationName;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  bool _cancelling = false;
  bool _scanning = false;

  BookingModel get booking => widget.booking;

  bool get _canCancel =>
      booking.status == BookingStatus.pending ||
      booking.status == BookingStatus.approved;

  bool get _canScanQr => booking.status == BookingStatus.approved;

  Future<void> _openQrScan() async {
    setState(() => _scanning = true);
    final started = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BookingQrScanScreen(booking: booking),
      ),
    );
    if (!mounted) return;
    setState(() => _scanning = false);
    if (started == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session started! Happy charging.',
              style: _dm(13, FontWeight.w500, color: Colors.white)),
          backgroundColor: _greenDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cancel booking?',
                  style: _sg(18, FontWeight.w800, ls: -0.3)),
              const SizedBox(height: 10),
              Text(
                'This releases your reserved charger bay at the station.',
                style: _dm(14, FontWeight.w400, color: _slate, h: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Keep',
                            style: _sg(14, FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Cancel booking',
                            style: _sg(14, FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    final result = await ChargixData.bookings.respondToBookingAtomic(
      booking: booking,
      status: BookingStatus.cancelled,
      rejectionReason: 'Cancelled by driver',
    );
    if (!mounted) return;
    setState(() => _cancelling = false);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking cancelled',
              style: _dm(13, FontWeight.w500, color: Colors.white)),
          backgroundColor: _ink,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.errorOrNull}',
              style: _dm(13, FontWeight.w500, color: Colors.white)),
          backgroundColor: _ink,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _canvas,
      body: Column(
        children: [
          // ── AppBar ───────────────────────────────────────────────────
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
                  child: Text('Booking details',
                      style: _sg(17, FontWeight.w700)),
                ),
              ],
            ),
          ),
          Container(height: 0.8, color: _border),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  16, 20, 16, 20 + bottomPad),
              children: [
                // Station + status header
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _greenSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(PhosphorIconsFill.lightning,
                            color: _greenDark, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.stationName ??
                                  'Station ${booking.stationId}',
                              style: _sg(15, FontWeight.w800, ls: -0.2),
                            ),
                            const SizedBox(height: 6),
                            _StatusChip(status: booking.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 340.ms)
                    .slideY(begin: 0.06, end: 0, duration: 340.ms,
                        curve: Curves.easeOut),

                const SizedBox(height: 16),

                // Time & port details card
                Container(
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
                    children: [
                      if (booking.scheduledStart != null)
                        _DetailRow(
                          icon: PhosphorIconsRegular.clockAfternoon,
                          label: 'Starts',
                          value: _fmt(booking.scheduledStart!),
                          isFirst: true,
                        ),
                      if (booking.scheduledEnd != null)
                        _DetailRow(
                          icon: PhosphorIconsRegular.calendarCheck,
                          label: 'Ends',
                          value: _fmt(booking.scheduledEnd!),
                        ),
                      if (booking.portNumber != null)
                        _DetailRow(
                          icon: PhosphorIconsRegular.plug,
                          label: 'Port',
                          value: '#${booking.portNumber}',
                        ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 60.ms, duration: 320.ms)
                    .slideY(begin: 0.06, end: 0, delay: 60.ms,
                        duration: 320.ms, curve: Curves.easeOut),

                // Notes card (if present)
                if (booking.notes != null &&
                    booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(PhosphorIconsRegular.notepad,
                            size: 16, color: _slate),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(booking.notes!,
                              style: _dm(13, FontWeight.w400,
                                  color: _slate, h: 1.5)),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 300.ms),
                ],

                // Scan QR to start session (approved bookings only)
                if (_canScanQr) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _scanning ? null : _openQrScan,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 54,
                      decoration: BoxDecoration(
                        color: _scanning
                            ? const Color(0xFFE5E7EB)
                            : _green,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _scanning
                            ? []
                            : [
                                BoxShadow(
                                  color: _green.withValues(alpha: 0.32),
                                  blurRadius: 18,
                                  spreadRadius: -4,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                      ),
                      alignment: Alignment.center,
                      child: _scanning
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _green.withValues(alpha: 0.7)),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(PhosphorIconsRegular.qrCode,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Text('Scan QR to start',
                                    style: _sg(15, FontWeight.w700,
                                        color: Colors.white, ls: 0.2)),
                              ],
                            ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 120.ms, duration: 300.ms),
                ],

                // Cancel button
                if (_canCancel) ...[
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _cancelling ? null : _cancelBooking,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 50,
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _cancelling
                                ? _border
                                : const Color(0xFFDC2626).withValues(alpha: 0.4),
                            width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: _cancelling
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        const Color(0xFFDC2626)
                                            .withValues(alpha: 0.6)),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(PhosphorIconsRegular.xCircle,
                                    color: Color(0xFFDC2626), size: 18),
                                const SizedBox(width: 8),
                                Text('Cancel booking',
                                    style: _sg(14, FontWeight.w600,
                                        color: const Color(0xFFDC2626))),
                              ],
                            ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 140.ms, duration: 300.ms),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${_weekday(d.weekday)}, ${_month(d.month)} ${d.day}  '
      '${_pad(d.hour)}:${_pad(d.minute)}';
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String _pad(int n) => n.toString().padLeft(2, '0');

String _weekday(int w) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];

String _month(int m) => const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][m - 1];

// ── Status chip ───────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.value.toUpperCase(),
        style: GoogleFonts.dmSans(
            fontSize: 10, fontWeight: FontWeight.w700, color: fg,
            letterSpacing: 0.5),
      ),
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isFirst = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isFirst) Divider(height: 1, color: _border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _greenSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 15, color: _greenDark),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
