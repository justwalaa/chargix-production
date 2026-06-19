import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Chargix splash screen — light canvas, green charge-up animation.
///
/// Sequence (total ~3.2 s):
///   0 ms    → background + logo mark scale-in (easeOutBack)
///   400 ms  → wordmark "CHARGIX" letter-by-letter fade in
///   700 ms  → tagline fades in
///   900 ms  → green charge bar fills 0 → 100 % (1 400 ms)
///   2 400 ms→ brief pause at full charge
///   2 800 ms→ full-screen fade-out → onComplete
///
/// Logo image: place `assets/images/chargix_logo.png` for a real logo.
/// Until then, the bolt-in-circle mark is used as the logotype.
class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _markCtrl;
  late final AnimationController _wordCtrl;
  late final AnimationController _chargeCtrl;
  late final AnimationController _exitCtrl;
  late final AnimationController _pulseCtrl;

  // ── Animations ────────────────────────────────────────────────────────────
  late final Animation<double> _markScale;
  late final Animation<double> _markOpacity;
  late final Animation<double> _wordOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _chargeProgress;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _pulse;

  static const _canvas = Color(0xFFF8F9FA);
  static const _green  = Color(0xFF22C55E);
  static const _ink    = Color(0xFF101828);
  static const _slate  = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    // Mark pop-in
    _markCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _markScale = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _markCtrl, curve: Curves.easeOutBack));
    _markOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _markCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));

    // Wordmark + tagline reveal
    _wordCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _wordOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _wordCtrl,
            curve: const Interval(0.0, 0.65, curve: Curves.easeOut)));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _wordCtrl,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    // Green charge bar
    _chargeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _chargeProgress = CurvedAnimation(
        parent: _chargeCtrl, curve: Curves.easeInOutCubic);

    // Bolt pulse (repeating glow while charging)
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Exit fade
    _exitCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 340));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    _markCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 360));
    if (!mounted) return;
    _wordCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    _chargeCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1650));
    if (!mounted) return;
    _pulseCtrl.stop();

    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    await _exitCtrl.forward();

    if (mounted) widget.onComplete?.call();
  }

  @override
  void dispose() {
    _markCtrl.dispose();
    _wordCtrl.dispose();
    _chargeCtrl.dispose();
    _pulseCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return FadeTransition(
      opacity: _exitOpacity,
      child: Scaffold(
        backgroundColor: _canvas,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Subtle top-right decorative arc ──────────────────────────
            Positioned(
              top: -size.width * 0.4,
              right: -size.width * 0.4,
              child: Container(
                width: size.width * 0.9,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _green.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -size.width * 0.6,
              right: -size.width * 0.6,
              child: Container(
                width: size.width * 1.3,
                height: size.width * 1.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _green.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
              ),
            ),

            // ── Bottom-left mirror arc ────────────────────────────────────
            Positioned(
              bottom: -size.width * 0.35,
              left: -size.width * 0.35,
              child: Container(
                width: size.width * 0.75,
                height: size.width * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _green.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
            ),

            // ── Centre logo + wordmark ────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo mark
                  AnimatedBuilder(
                    animation: _markCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _markOpacity.value,
                      child: Transform.scale(
                        scale: _markScale.value,
                        child: child,
                      ),
                    ),
                    child: _LogoMark(pulse: _pulse),
                  ),

                  const SizedBox(height: 24),

                  // Wordmark
                  AnimatedBuilder(
                    animation: _wordCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _wordOpacity.value,
                      child: child,
                    ),
                    child: Text(
                      'CHARGIX',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: 8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  AnimatedBuilder(
                    animation: _wordCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _taglineOpacity.value,
                      child: child,
                    ),
                    child: Text(
                      'CHARGE SMARTER. DRIVE FURTHER.',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _slate,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Charge bar at bottom ──────────────────────────────────────
            Positioned(
              bottom: 56,
              left: 40,
              right: 40,
              child: AnimatedBuilder(
                animation: _chargeProgress,
                builder: (_, _) =>
                    _ChargeBar(progress: _chargeProgress.value),
              ),
            ),

            // ── Version ───────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _wordCtrl,
              builder: (_, child) => Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _taglineOpacity.value,
                  child: child,
                ),
              ),
              child: Text(
                'v1.0.0',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: _slate,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logo mark ─────────────────────────────────────────────────────────────────
// Shows chargix_logo.png if found; falls back to bolt-in-circle.
class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.pulse});
  final Animation<double> pulse;

  static const _green   = Color(0xFF22C55E);
  static const _greenDk = Color(0xFF16A34A);
  static const _greenSf = Color(0xFFDCFCE7);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring — pulses while charging
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _green.withValues(alpha: 0.06 * pulse.value),
              ),
            ),
            // Inner mark
            child!,
          ],
        );
      },
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _greenSf,
          border: Border.all(color: _green.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: 0.18),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/chargix_logo.png',
          width: 46,
          height: 46,
          errorBuilder: (context, error, _) => CustomPaint(
            size: const Size(46, 46),
            painter: _BoltPainter(color: _greenDk),
          ),
        ),
      ),
    );
  }
}

// ── Bolt custom painter (fallback logo mark) ─────────────────────────────────
class _BoltPainter extends CustomPainter {
  const _BoltPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.58, h * 0.04)
      ..lineTo(w * 0.28, h * 0.52)
      ..lineTo(w * 0.50, h * 0.52)
      ..lineTo(w * 0.42, h * 0.96)
      ..lineTo(w * 0.72, h * 0.48)
      ..lineTo(w * 0.50, h * 0.48)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BoltPainter old) => old.color != color;
}

// ── Green charge bar ──────────────────────────────────────────────────────────
class _ChargeBar extends StatelessWidget {
  const _ChargeBar({required this.progress});
  final double progress;

  static const _green   = Color(0xFF22C55E);
  static const _greenDk = Color(0xFF16A34A);
  static const _border  = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Charging…',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 0.3,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              // Track
              Container(
                height: 4,
                width: double.infinity,
                color: _border,
              ),
              // Fill with animated width
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_green, _greenDk],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.45),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
