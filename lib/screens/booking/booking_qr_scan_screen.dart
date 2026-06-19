import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/chargix_data.dart';
import '../../models/booking_model.dart';
import '../../models/enums/booking_status.dart';

// Design tokens
const _green        = Color(0xFF22C55E);
const _greenSurface = Color(0xFFDCFCE7);

/// Opens the camera scanner. When the QR matches the booking's station + slot,
/// and the booking is approved, transitions it to [BookingStatus.active].
class BookingQrScanScreen extends StatefulWidget {
  const BookingQrScanScreen({super.key, required this.booking});
  final BookingModel booking;

  @override
  State<BookingQrScanScreen> createState() => _BookingQrScanScreenState();
}

class _BookingQrScanScreenState extends State<BookingQrScanScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _handled = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled || _loading) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    // Parse chargix://station/{stationId}/bay/{slotId}/booking/{bookingId}
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        uri.scheme != 'chargix' ||
        uri.host != 'station' ||
        uri.pathSegments.length < 5 ||
        uri.pathSegments[1] != 'bay' ||
        uri.pathSegments[3] != 'booking') {
      _setError('Not a valid Chargix bay QR code.');
      return;
    }

    final scannedStationId = uri.pathSegments[0];
    final scannedSlotId = uri.pathSegments[2];
    final scannedBookingId = uri.pathSegments[4];

    // Validate against booking
    if (scannedStationId != widget.booking.stationId) {
      _setError('QR does not match this booking\'s station.');
      return;
    }
    if (scannedSlotId != widget.booking.slotId) {
      _setError('QR does not match this booking\'s bay.');
      return;
    }
    if (scannedBookingId != widget.booking.id) {
      _setError('QR does not match this booking.');
      return;
    }
    if (widget.booking.status != BookingStatus.approved &&
        widget.booking.status != BookingStatus.confirmed) {
      _setError('Booking must be approved before scanning.');
      return;
    }

    // Optional: time-window check (within 30 min of scheduled start)
    final start = widget.booking.scheduledStart;
    if (start != null) {
      final now = DateTime.now();
      final diff = start.difference(now).inMinutes;
      if (diff > 30) {
        _setError(
            'Too early — session starts at ${_fmt(start)}. '
            'Scan within 30 minutes of your slot.');
        return;
      }
    }

    setState(() { _handled = true; _loading = true; _error = null; });

    final result = await ChargixData.bookings.respondToBookingAtomic(
      booking: widget.booking,
      status: BookingStatus.active,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.isSuccess) {
      // Increment QR-verified booking stat for driver
      await ChargixData.users.incrementBookingStats(
        widget.booking.userId,
        qrVerified: true,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true); // signal success to caller
    } else {
      setState(() {
        _handled = false;
        _error = 'Could not start session: ${result.errorOrNull}';
      });
    }
  }

  void _setError(String msg) {
    if (mounted) setState(() => _error = msg);
  }

  String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scanner,
            onDetect: _onDetect,
          ),

          // Scan frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: _green, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: topPad + 8,
            left: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(PhosphorIconsRegular.arrowLeft,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          Positioned(
            top: topPad + 16,
            left: 0,
            right: 0,
            child: Text('Scan bay QR',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: _green),
                    const SizedBox(height: 16),
                    Text('Starting session…',
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),

          // Error banner
          if (_error != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: bottomPad + 80,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.warningCircle,
                        color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!,
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: const Color(0xFFDC2626),
                              height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom hint
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomPad + 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: _green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Point at the QR on the charger bay',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: _greenSurface),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
