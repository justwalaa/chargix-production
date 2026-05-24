import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:chargix_production/core/app_settings_scope.dart';
import 'package:chargix_production/core/routing/session_gate.dart';
import 'package:chargix_production/screens/auth/login_screen.dart';
import 'package:chargix_production/theme/app_theme.dart';
import 'package:chargix_production/widgets/auth/session_loading_screen.dart';

/// Production shell — auth listener + single navigator (no nested MaterialApp).
class ChargixApp extends StatefulWidget {
  const ChargixApp({super.key});

  @override
  State<ChargixApp> createState() => _ChargixAppState();
}

class _ChargixAppState extends State<ChargixApp> {
  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  Widget _rootScreen = const SessionLoadingScreen(message: 'Starting Chargix…');
  String _sessionKey = 'boot';
  int _resolveGeneration = 0;
  late final StreamSubscription<User?> _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChange);
  }

  Future<void> _onAuthChange(User? user) async {
    final generation = ++_resolveGeneration;
    final uid = user?.uid;

    if (uid == null) {
      if (!mounted || generation != _resolveGeneration) return;
      _applyRoot(
        sessionKey: 'signed-out',
        screen: const LoginScreen(),
      );
      return;
    }

    if (mounted) {
      _applyRoot(
        sessionKey: uid,
        screen: const SessionLoadingScreen(message: 'Loading your session…'),
      );
    }

    Widget screen;
    try {
      screen = await SessionGate.resolveHome();
    } catch (e, st) {
      debugPrint('Chargix: auth bootstrap failed: $e\n$st');
      screen = const LoginScreen();
    }

    if (!mounted || generation != _resolveGeneration) return;
    _applyRoot(sessionKey: uid, screen: screen);
  }

  /// Replaces the entire navigator stack — clears OTP/login overlays.
  void _applyRoot({required String sessionKey, required Widget screen}) {
    setState(() {
      _sessionKey = sessionKey;
      _rootScreen = screen;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = _rootNavigatorKey.currentState;
      if (nav == null) return;
      nav.pushAndRemoveUntil(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => screen,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey<String>('chargix-$_sessionKey'),
      navigatorKey: _rootNavigatorKey,
      title: 'Chargix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: AppSettingsScope.of(context).themeMode,
      home: _rootScreen,
    );
  }
}
