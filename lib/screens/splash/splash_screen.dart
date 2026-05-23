import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Premium Chargix Splash Screen
/// Dark EV-charging aesthetic with animated car, glow effects, and brand reveal.
/// Calls [onComplete] when the sequence finishes.
class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const SplashScreen({
    super.key,
    this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _bgController;
  late final AnimationController _carController;
  late final AnimationController _glowController;
  late final AnimationController _logoController;
  late final AnimationController _loadController;
  late final AnimationController _exitController;

  // ── Animations ────────────────────────────────────────────────────────────
  late final Animation<double> _bgOpacity;
  late final Animation<double> _carX;        // car slide-in
  late final Animation<double> _carOpacity;
  late final Animation<double> _glowPulse;   // repeating bolt glow
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _loadProgress;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    // ── Background fade-in (0 → 600 ms) ─────────────────────────────────
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgOpacity = CurvedAnimation(parent: _bgController, curve: Curves.easeIn);

    // ── Car slide-in from left (400 → 1200 ms) ────────────────────────────
    _carController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _carX = Tween<double>(begin: -1.6, end: 0.0).animate(
      CurvedAnimation(parent: _carController, curve: Curves.easeOutCubic),
    );
    _carOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _carController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // ── Glow pulse – repeats (starts at 800 ms) ───────────────────────────
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // ── Logo reveal (1000 → 1600 ms) ─────────────────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // ── Loading bar (1400 → 2800 ms) ──────────────────────────────────────
    _loadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _loadProgress = CurvedAnimation(
      parent: _loadController,
      curve: Curves.easeInOutCubic,
    );

    // ── Exit fade-out (3000 → 3300 ms) ───────────────────────────────────
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    _bgController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _carController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _loadController.forward();

    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    _glowController.stop();
    await _exitController.forward();

    if (mounted) widget.onComplete?.call();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _carController.dispose();
    _glowController.dispose();
    _logoController.dispose();
    _loadController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  // ── Colours ───────────────────────────────────────────────────────────────
  static const _bgTop    = Color(0xFF080B14);
  static const _bgBottom = Color(0xFF060A10);
  static const _electric = Color(0xFF00D4FF);   // cyan-electric accent
  static const _electricDim = Color(0xFF0098CC);
  static const _gold     = Color(0xFF4FC3F7);   // cool-blue "gold"
  static const _white    = Color(0xFFEEF4FF);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _exitOpacity,
      child: FadeTransition(
        opacity: _bgOpacity,
        child: Scaffold(
          backgroundColor: _bgTop,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background gradient ──────────────────────────────────
              _Background(size: size),

              // ── Grid lines – subtle depth ────────────────────────────
              CustomPaint(painter: _GridPainter()),

              // ── Animated car ─────────────────────────────────────────
              _AnimatedCar(
                xFraction: _carX,
                opacity: _carOpacity,
                size: size,
              ),

              // ── Ground glow beneath car ──────────────────────────────
              AnimatedBuilder(
                animation: _glowPulse,
                builder: (_, __) => Positioned(
                  bottom: size.height * 0.28,
                  left: 0,
                  right: 0,
                  child: _GroundGlow(intensity: _glowPulse.value),
                ),
              ),

              // ── Charging cable + bolt ─────────────────────────────────
              AnimatedBuilder(
                animation: _glowPulse,
                builder: (_, __) => Positioned(
                  right: size.width * 0.08,
                  bottom: size.height * 0.30,
                  child: _ChargingBolt(intensity: _glowPulse.value),
                ),
              ),

              // ── Logo + tagline ────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height * 0.04),
                    // Push logo into lower centre of screen
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (_, __) => Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: _Logo(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (_, __) => Opacity(
                        opacity: _taglineOpacity.value,
                        child: const Text(
                          'CHARGE SMARTER. DRIVE FURTHER.',
                          style: TextStyle(
                            color: _electricDim,
                            fontSize: 10.5,
                            letterSpacing: 2.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.32),
                  ],
                ),
              ),

              // ── Loading bar at bottom ────────────────────────────────
              Positioned(
                bottom: 52,
                left: 36,
                right: 36,
                child: AnimatedBuilder(
                  animation: _loadProgress,
                  builder: (_, __) =>
                      _LoadingBar(progress: _loadProgress.value),
                ),
              ),

              // ── Version label ─────────────────────────────────────────
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _logoController,
                  builder: (_, __) => Opacity(
                    opacity: _taglineOpacity.value,
                    child: const Text(
                      'v1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF3A4A60),
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Sub-widgets
// ═══════════════════════════════════════════════════════════════════════════

class _Background extends StatelessWidget {
  final Size size;
  const _Background({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Main gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF080B14),
                Color(0xFF0A0F1C),
                Color(0xFF060A10),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Radial glow at top-centre (like a far-off light)
        Positioned(
          top: -size.height * 0.1,
          left: size.width * 0.1,
          right: size.width * 0.1,
          child: Container(
            height: size.height * 0.6,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Color(0x1500D4FF),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Grid / road-perspective lines ──────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0800D4FF)
      ..strokeWidth = 0.5;

    // Horizontal lines (perspective road)
    final horizonY = size.height * 0.58;
    for (int i = 0; i < 8; i++) {
      final t = i / 8.0;
      final y = horizonY + (size.height - horizonY) * t * t;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical convergence lines
    final vp = Offset(size.width / 2, horizonY);
    for (int i = -3; i <= 3; i++) {
      final endX = size.width / 2 + i * size.width * 0.18;
      canvas.drawLine(vp, Offset(endX, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Animated EV car (drawn with CustomPainter) ────────────────────────────
class _AnimatedCar extends StatelessWidget {
  final Animation<double> xFraction;
  final Animation<double> opacity;
  final Size size;

  const _AnimatedCar({
    required this.xFraction,
    required this.opacity,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: xFraction,
      builder: (_, __) {
        final dx = xFraction.value * size.width;
        return Positioned(
          bottom: size.height * 0.29,
          left: dx + size.width * 0.06,
          child: Opacity(
            opacity: opacity.value,
            child: SizedBox(
              width: size.width * 0.78,
              height: size.height * 0.14,
              child: CustomPaint(painter: _CarPainter()),
            ),
          ),
        );
      },
    );
  }
}

class _CarPainter extends CustomPainter {
  static const _electric = Color(0xFF00D4FF);
  static const _bodyColor = Color(0xFF0F1A2E);
  static const _bodyMid   = Color(0xFF192640);
  static const _highlight = Color(0xFF1E3A5F);
  static const _glassColor= Color(0xFF1A4A7A);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Shadow beneath car ─────────────────────────────────────────────
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0x6000D4FF), Colors.transparent],
      ).createShader(Rect.fromLTWH(w * 0.1, h * 0.85, w * 0.8, h * 0.2));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.95), width: w * 0.7, height: h * 0.12),
      shadowPaint,
    );

    // ── Car body (sleek sedan silhouette) ─────────────────────────────
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_bodyMid, _bodyColor],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Lower body
    final body = Path()
      ..moveTo(w * 0.04, h * 0.72)
      ..lineTo(w * 0.04, h * 0.60)
      ..lineTo(w * 0.10, h * 0.50)
      ..lineTo(w * 0.25, h * 0.28)
      ..lineTo(w * 0.72, h * 0.22)
      ..lineTo(w * 0.88, h * 0.42)
      ..lineTo(w * 0.96, h * 0.55)
      ..lineTo(w * 0.96, h * 0.72)
      ..close();
    canvas.drawPath(body, bodyPaint);

    // Highlight stripe
    final hlPaint = Paint()
      ..color = _highlight
      ..style = PaintingStyle.fill;
    final hlPath = Path()
      ..moveTo(w * 0.10, h * 0.50)
      ..lineTo(w * 0.25, h * 0.29)
      ..lineTo(w * 0.72, h * 0.23)
      ..lineTo(w * 0.85, h * 0.43)
      ..lineTo(w * 0.70, h * 0.30)
      ..lineTo(w * 0.25, h * 0.35)
      ..lineTo(w * 0.13, h * 0.55)
      ..close();
    canvas.drawPath(hlPath, hlPaint);

    // ── Windshield + windows ──────────────────────────────────────────
    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_glassColor, const Color(0xFF0D2E50)],
      ).createShader(Rect.fromLTWH(w * 0.22, h * 0.22, w * 0.55, h * 0.28));

    // Windshield
    final wind = Path()
      ..moveTo(w * 0.27, h * 0.46)
      ..lineTo(w * 0.32, h * 0.28)
      ..lineTo(w * 0.55, h * 0.25)
      ..lineTo(w * 0.55, h * 0.44)
      ..close();
    canvas.drawPath(wind, glassPaint);

    // Rear window
    final rear = Path()
      ..moveTo(w * 0.57, h * 0.44)
      ..lineTo(w * 0.57, h * 0.25)
      ..lineTo(w * 0.72, h * 0.25)
      ..lineTo(w * 0.82, h * 0.44)
      ..close();
    canvas.drawPath(rear, glassPaint);

    // ── Electric accent strip (bottom of car) ─────────────────────────
    final stripPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, _electric, _electric, Colors.transparent],
        stops: const [0.0, 0.2, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, h * 0.70, w, h * 0.04))
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.06, h * 0.700, w * 0.88, h * 0.028), stripPaint);

    // ── Headlight (right) ─────────────────────────────────────────────
    final headlightGlow = Paint()
      ..shader = RadialGradient(
        colors: [_electric, Colors.transparent],
      ).createShader(Rect.fromLTWH(w * 0.86, h * 0.50, w * 0.18, h * 0.18));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.94, h * 0.58), width: w * 0.08, height: h * 0.10),
      headlightGlow,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.94, h * 0.58), width: w * 0.04, height: h * 0.06),
      Paint()..color = _electric,
    );

    // ── Tail light (left) ─────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.06, h * 0.58), width: w * 0.025, height: h * 0.05),
      Paint()..color = const Color(0xFFFF3D3D),
    );

    // ── Wheels ────────────────────────────────────────────────────────
    _drawWheel(canvas, Offset(w * 0.22, h * 0.80), w * 0.12);
    _drawWheel(canvas, Offset(w * 0.76, h * 0.80), w * 0.12);
  }

  void _drawWheel(Canvas canvas, Offset center, double r) {
    // Tire
    canvas.drawCircle(center, r / 2, Paint()..color = const Color(0xFF111826));
    canvas.drawCircle(
      center, r / 2,
      Paint()
        ..color = const Color(0xFF1E2A3A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08,
    );
    // Rim
    canvas.drawCircle(center, r * 0.28, Paint()..color = const Color(0xFF243040));
    // Spokes
    final spokePaint = Paint()
      ..color = const Color(0xFF2E4060)
      ..strokeWidth = r * 0.06;
    for (int i = 0; i < 5; i++) {
      final angle = i * 2 * math.pi / 5;
      canvas.drawLine(
        center,
        Offset(center.dx + math.cos(angle) * r * 0.38,
            center.dy + math.sin(angle) * r * 0.38),
        spokePaint,
      );
    }
    // Hub glow
    canvas.drawCircle(center, r * 0.10, Paint()..color = const Color(0xFF00D4FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Ground glow ────────────────────────────────────────────────────────────
class _GroundGlow extends StatelessWidget {
  final double intensity;
  const _GroundGlow({required this.intensity});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Color.fromRGBO(0, 212, 255, intensity * 0.18),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ── Charging bolt + cable ─────────────────────────────────────────────────
class _ChargingBolt extends StatelessWidget {
  final double intensity;
  const _ChargingBolt({required this.intensity});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 212, 255, intensity * 0.45),
                blurRadius: 28,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
        // Bolt icon
        Icon(
          Icons.bolt_rounded,
          size: 42,
          color: Color.fromRGBO(0, 212, 255, 0.4 + intensity * 0.6),
        ),
      ],
    );
  }
}

// ── Chargix logo ───────────────────────────────────────────────────────────
class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icon mark
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00D4FF),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withAlpha(70),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
                gradient: const RadialGradient(
                  colors: [Color(0xFF0D1F35), Color(0xFF080B14)],
                ),
              ),
            ),
            const Icon(Icons.bolt_rounded, color: Color(0xFF00D4FF), size: 36),
          ],
        ),
        const SizedBox(height: 16),
        // Wordmark
        const Text(
          'CHARGIX',
          style: TextStyle(
            color: Color(0xFFEEF4FF),
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 10,
          ),
        ),
      ],
    );
  }
}

// ── Loading bar ────────────────────────────────────────────────────────────
class _LoadingBar extends StatelessWidget {
  final double progress;
  const _LoadingBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            children: [
              // Track
              Container(
                height: 2,
                color: const Color(0xFF1A2A40),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0070AA), Color(0xFF00D4FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x8800D4FF),
                        blurRadius: 8,
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
