import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _green        = Color(0xFF22C55E);
const _greenSurface = Color(0xFFDCFCE7);
const _canvas       = Color(0xFFF8F9FA);
const _white        = Color(0xFFFFFFFF);
const _ink          = Color(0xFF101828);
const _slate        = Color(0xFF6B7280);
const _border       = Color(0xFFE5E7EB);

/// Shown while a partner station awaits admin approval.
class StationApprovalPendingScreen extends StatelessWidget {
  const StationApprovalPendingScreen(
      {super.key, required this.stationId});
  final String stationId;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 0, 28, 20 + bottomPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Icon
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: _greenSurface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.2),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(PhosphorIconsRegular.hourglass,
                      color: _green, size: 44),
                )
                    .animate()
                    .scale(begin: const Offset(0.6, 0.6),
                        duration: 500.ms, curve: Curves.easeOutBack)
                    .fadeIn(duration: 400.ms),
              ),

              const SizedBox(height: 28),

              Text(
                'Application under review',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.4),
              )
                  .animate()
                  .fadeIn(delay: 120.ms, duration: 360.ms)
                  .slideY(begin: 0.1, end: 0, delay: 120.ms,
                      duration: 360.ms, curve: Curves.easeOut),

              const SizedBox(height: 12),

              Text(
                'Your station registration was submitted successfully. '
                'Chargix will verify your details before activating partner '
                'bookings on the map.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _slate,
                    height: 1.6),
              )
                  .animate()
                  .fadeIn(delay: 180.ms, duration: 340.ms),

              const SizedBox(height: 32),

              // Checklist
              for (final item in [
                'Registration received',
                'Team review in progress',
                'Activation on Chargix map',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsFill.checkCircle,
                          size: 16, color: _green),
                      const SizedBox(width: 10),
                      Text(item,
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: _slate)),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 240.ms, duration: 300.ms),

              const Spacer(flex: 2),

              // Station ID
              Text(
                'Station ID: $stationId',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFD1D5DB)),
              ),

              const SizedBox(height: 16),

              // Sign out
              GestureDetector(
                onTap: () async =>
                    FirebaseAuth.instance.signOut(),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Text('Sign out',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _ink)),
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
