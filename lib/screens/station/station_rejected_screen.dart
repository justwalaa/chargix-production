import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _canvas = Color(0xFFF8F9FA);
const _white  = Color(0xFFFFFFFF);
const _ink    = Color(0xFF101828);
const _slate  = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);

/// Shown when a partner station's application was rejected.
class StationRejectedScreen extends StatelessWidget {
  const StationRejectedScreen({super.key, required this.stationId});
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

              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(PhosphorIconsRegular.xCircle,
                      color: Color(0xFFDC2626), size: 40),
                )
                    .animate()
                    .scale(begin: const Offset(0.6, 0.6),
                        duration: 480.ms, curve: Curves.easeOutBack)
                    .fadeIn(duration: 380.ms),
              ),

              const SizedBox(height: 28),

              Text(
                'Registration not approved',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.4),
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 340.ms)
                  .slideY(begin: 0.1, end: 0, delay: 100.ms,
                      duration: 340.ms, curve: Curves.easeOut),

              const SizedBox(height: 12),

              Text(
                'Your station application was reviewed and could not be '
                'approved at this time. Contact support for details.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _slate,
                    height: 1.6),
              ).animate().fadeIn(delay: 160.ms, duration: 320.ms),

              const SizedBox(height: 24),

              // Support contact
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsRegular.envelope,
                        size: 16, color: _slate),
                    const SizedBox(width: 10),
                    Text('support@chargix.app',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _ink)),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              const Spacer(flex: 2),

              GestureDetector(
                onTap: () async =>
                    FirebaseAuth.instance.signOut(),
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text('Sign out',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ).animate().fadeIn(delay: 240.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
