import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:chargix_production/core/app_settings_scope.dart';
import 'package:chargix_production/core/routing/session_gate.dart';
import 'package:chargix_production/screens/auth/login_screen.dart';
import 'package:chargix_production/theme/app_theme.dart';
import 'package:chargix_production/widgets/auth/session_loading_screen.dart';

/// Production shell — auth listener + single navigator (no nested MaterialApp).
///
/// Auth flow:
///   1. Auth stream fires → show SessionLoadingScreen instantly.
///   2. SessionGate.resolveHome() fetches profile from Firestore.
///   3. pushAndRemoveUntil replaces the stack with the resolved home shell.
///
/// IMPORTANT: MaterialApp has NO ValueKey so it is never destroyed/recreated
/// on session changes. Only the navigator stack changes via pushAndRemoveUntil.
class ChargixApp extends StatefulWidget {
  const ChargixApp({super.key});

  @override
  State<ChargixApp> createState() => _ChargixAppState();
}

class _ChargixAppState extends State<ChargixApp> {
  final GlobalKey<NavigatorState> _rootNavigatorKey =
  GlobalKey<NavigatorState>();

  /// Initial home shown while the first auth event is awaited.
  Widget _rootScreen =
  const SessionLoadingScreen(message: 'Starting Chargix…');

  /// Incremented each auth event to discard stale async completions.
  int _resolveGeneration = 0;

  late final StreamSubscription<User?> _authSub;

  @override
  void initState() {
    super.initState();
    // Listen once — no duplicate subscriptions, no stuck loaders.
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChange);
  }

  Future<void> _onAuthChange(User? user) async {
    final generation = ++_resolveGeneration;
    final uid = user?.uid;

    // ── Signed out ────────────────────────────────────────────────────────
    if (uid == null) {
      if (!mounted || generation != _resolveGeneration) return;
      _applyRoot(const LoginScreen());
      return;
    }

    // ── Signed in — show loading immediately, then resolve ────────────────
    if (mounted) {
      _applyRoot(const SessionLoadingScreen(message: 'Loading your session…'));
    }

    Widget screen;
    try {
      screen = await SessionGate.resolveHome();
    } catch (e, st) {
      debugPrint('Chargix: auth bootstrap failed: $e\n$st');
      screen = const LoginScreen();
    }

    // Discard if a newer auth event fired while we were resolving.
    if (!mounted || generation != _resolveGeneration) return;
    _applyRoot(screen);
  }

  /// Instantly replaces the entire navigator stack with [screen].
  ///
  /// Uses pushAndRemoveUntil so OTP / login overlays are always cleared.
  /// Does NOT mutate MaterialApp's key — avoids full widget-tree rebuild.
  void _applyRoot(Widget screen) {
    // Update the home reference (used if navigator is not yet ready).
    if (mounted) setState(() => _rootScreen = screen);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = _rootNavigatorKey.currentState;
      if (nav == null) return;
      nav.pushAndRemoveUntil(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => screen,
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
    // No ValueKey — MaterialApp is never recreated between sessions.
    return MaterialApp(
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