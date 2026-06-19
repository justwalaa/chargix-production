import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _green        = Color(0xFF22C55E);
const _greenDark    = Color(0xFF16A34A);
const _greenSurface = Color(0xFFDCFCE7);
const _canvas       = Color(0xFFF8F9FA);
const _white        = Color(0xFFFFFFFF);
const _ink          = Color(0xFF101828);
const _slate        = Color(0xFF6B7280);
const _border       = Color(0xFFE5E7EB);

/// Payment methods placeholder — ready for Stripe / local wallets.
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

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
                  child: Text('Payment Methods',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                ),
              ],
            ),
          ),
          Container(height: 0.8, color: _border),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + bottomPad),
              children: [
                // Coming soon card
                Container(
                  padding: const EdgeInsets.all(20),
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
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: _greenSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(PhosphorIconsFill.creditCard,
                            color: _greenDark, size: 26),
                      ),
                      const SizedBox(height: 16),
                      Text('Payments coming soon',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 8),
                      Text(
                        'Chargix will support cards and mobile wallets for session billing. '
                        'Your charging history is tracked in Firestore today.',
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: _slate,
                            height: 1.55),
                      ),
                      const SizedBox(height: 20),
                      for (final item in [
                        'Credit & debit cards',
                        'Jordan mobile wallets (eFawateercom)',
                        'Apple Pay & Google Pay',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(PhosphorIconsRegular.clock,
                                  size: 13, color: _slate),
                              const SizedBox(width: 8),
                              Text(item,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: _slate)),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 40.ms, duration: 320.ms)
                    .slideY(begin: 0.05, end: 0, delay: 40.ms,
                        duration: 320.ms, curve: Curves.easeOut),

                const SizedBox(height: 16),

                // Add method button (placeholder)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Payment provider integration is planned.',
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                        backgroundColor: _ink,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _green.withValues(alpha: 0.4),
                          width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsRegular.plus,
                            color: _green, size: 16),
                        const SizedBox(width: 8),
                        Text('Add payment method',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _green)),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 300.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
