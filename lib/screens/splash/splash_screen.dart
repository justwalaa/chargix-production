import 'package:flutter/material.dart';

import '../../core/routing/session_gate.dart';
import '../../services/auth_service.dart';
import '../../theme/app_gradients.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/chargix_brand_lockup.dart';
import '../auth/login_screen.dart';

/// Animated entry; routes by validated phone session only.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.72, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _scale = Tween<double>(begin: 0.88, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: AppMotion.emphasized),
  );

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 2200), _goNext);
  }

  Future<void> _goNext() async {
    if (!mounted || _navigated) {
      return;
    }
    _navigated = true;

    final signedIn = await AuthService.instance.hasValidSession();
    if (!mounted) {
      return;
    }

    final next = signedIn ? await SessionGate.resolveHome() : const LoginScreen();
    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: AppMotion.slow,
        pageBuilder: (context, animation, secondaryAnimation) => next,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: AppMotion.standard),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? AppGradients.heroDark
              : AppGradients.hero(context),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fade.value,
                  child: Transform.scale(scale: _scale.value, child: child),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const ChargixBrandLockup(compact: false),
                    const SizedBox(height: AppSpacing.xxl),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
