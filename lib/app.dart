import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:chargix_production/core/routing/session_gate.dart';
import 'package:chargix_production/screens/auth/login_screen.dart';

class ChargixApp extends StatefulWidget {
  const ChargixApp({super.key});

  @override
  State<ChargixApp> createState() => _ChargixAppState();
}

class _ChargixAppState extends State<ChargixApp> {
  /// Current home widget shown by MaterialApp.
  Widget _home = const _AuthLoadingScreen();

  /// Last UID we resolved routing for.
  /// Sentinel '' ensures the first stream event (even null) triggers resolution.
  String? _lastUid = '';

  late final StreamSubscription<User?> _authSub;

  @override
  void initState() {
    super.initState();
    // authStateChanges emits the current state immediately, so the first call
    // to _onAuthChange runs synchronously on the next microtask — no extra
    // initState kick needed.
    _authSub = FirebaseAuth.instance
        .authStateChanges()
        .listen(_onAuthChange);
  }

  Future<void> _onAuthChange(User? user) async {
    final uid = user?.uid;

    // Guard: only re-resolve when UID actually changes.
    // '' (initial sentinel) ≠ null → first call always runs.
    // null == null → spurious null re-emissions during reCAPTCHA are ignored.
    // uid1 == uid1 → re-hydrations of the same session are ignored.
    if (uid == _lastUid) return;
    _lastUid = uid;

    final Widget home;
    if (uid == null) {
      // Not authenticated — go straight to driver login.
      // Avoids an unnecessary Firestore round-trip.
      home = const LoginScreen();
    } else {
      // Authenticated — resolve role-based home via real production logic.
      home = await SessionGate.resolveHome();
    }

    if (mounted) setState(() => _home = home);
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chargix',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: _home,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF080B14),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00D4FF),
        secondary: Color(0xFF0098CC),
        surface: Color(0xFF0A0F1C),
        onPrimary: Color(0xFF080B14),
        onSurface: Color(0xFFEEF4FF),
        error: Color(0xFFFF4D6A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0F1C),
        foregroundColor: Color(0xFFEEF4FF),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFFEEF4FF),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1526),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF4D6A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF4D6A), width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF5A7FA8)),
        hintStyle: const TextStyle(color: Color(0xFF2E4060)),
        errorStyle: const TextStyle(color: Color(0xFFFF4D6A), fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00D4FF),
          foregroundColor: const Color(0xFF080B14),
          disabledBackgroundColor: const Color(0xFF1E3A5F),
          disabledForegroundColor: const Color(0xFF2E4060),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.8,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF00D4FF),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF0A0F1C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1A2840), width: 0.8),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1A2840),
        thickness: 0.8,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF00D4FF)),
      useMaterial3: true,
    );
  }
}

/// Minimal dark loading indicator shown while auth state / Firestore resolves.
class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF080B14),
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
          ),
        ),
      ),
    );
  }
}