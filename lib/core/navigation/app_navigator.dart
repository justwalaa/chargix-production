// lib/core/navigation/app_navigator.dart
//
// Global navigator key used by:
//   1. app.dart (MaterialApp.navigatorKey)
//   2. OtpScreen after signInWithCredential — clears auth stack instantly
//   3. Any service that needs to navigate without a BuildContext
//
// Using the same key throughout means there is ONE navigator, no stack split.

import 'package:flutter/material.dart';

abstract final class AppNavigator {
  AppNavigator._();

  /// Single key wired into MaterialApp.navigatorKey.
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static NavigatorState get _nav => key.currentState!;

  // ── Navigation helpers ────────────────────────────────────────────────────

  /// Clear every existing route and push [page].
  /// Used after successful authentication so no auth screen remains on stack.
  static Future<T?> pushReplaceAll<T extends Object?>(Widget page) {
    return _nav.pushAndRemoveUntil<T>(
      _smoothRoute(page),
          (_) => false,
    );
  }

  /// Standard push with the app's default fade+slide transition.
  static Future<T?> push<T extends Object?>(Widget page) {
    return _nav.push<T>(_smoothRoute(page));
  }

  /// Pop the current route.
  static void pop<T extends Object?>([T? result]) => _nav.pop(result);

  // ── Route builder ──────────────────────────────────────────────────────────

  static PageRouteBuilder<T> _smoothRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }
}