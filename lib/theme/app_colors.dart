// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Single source of truth for all Chargix colors.
///
/// Design language: deep cosmos backgrounds, electric cyan primary,
/// violet secondary, neon green for live/active states.
abstract final class AppColors {
  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const Color bg0 = Color(0xFF030508); // Deepest — used behind gradients
  static const Color bg1 = Color(0xFF080B14); // Main scaffold background
  static const Color bg2 = Color(0xFF0A0F1C); // Surface / card base
  static const Color bg3 = Color(0xFF0D1525); // Elevated card
  static const Color bg4 = Color(0xFF111E35); // Input fill / deep card

  // ── Electric Cyan (primary) ───────────────────────────────────────────────
  static const Color cyan    = Color(0xFF00D4FF);
  static const Color cyanMid = Color(0xFF0098CC);
  static const Color cyanDeep = Color(0xFF006699);

  // ── Electric Violet (secondary) ───────────────────────────────────────────
  static const Color violet     = Color(0xFF7B3FE4);
  static const Color violetMid  = Color(0xFF5A2DB8);
  static const Color violetDeep = Color(0xFF3D1D8A);

  // ── Neon Green (active / available / charging) ────────────────────────────
  static const Color neonGreen    = Color(0xFF00FF94);
  static const Color neonGreenMid = Color(0xFF00C472);

  // ── Amber (busy / partial) ────────────────────────────────────────────────
  static const Color amber    = Color(0xFFFFB800);
  static const Color amberMid = Color(0xFFCC9300);

  // ── Red (offline / error) ─────────────────────────────────────────────────
  static const Color red    = Color(0xFFFF4D6A);
  static const Color redMid = Color(0xFFCC3355);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFEEF4FF);
  static const Color textSecondary = Color(0xFF8AAAC8);
  static const Color textTertiary  = Color(0xFF4A6A8A);
  static const Color textMuted     = Color(0xFF1E3A5F);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color border1 = Color(0xFF162030); // Subtle divider
  static const Color border2 = Color(0xFF1E3A5F); // Standard card border
  static const Color border3 = Color(0xFF2A4A6A); // Hover / focused border

  // ── Glow helpers (use in BoxShadow) ───────────────────────────────────────
  static Color cyanGlow([double opacity = 0.25])   => cyan.withAlpha((opacity * 255).round());
  static Color violetGlow([double opacity = 0.25]) => violet.withAlpha((opacity * 255).round());
  static Color greenGlow([double opacity = 0.25])  => neonGreen.withAlpha((opacity * 255).round());
  static Color redGlow([double opacity = 0.25])    => red.withAlpha((opacity * 255).round());

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0098CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = LinearGradient(
    colors: [Color(0xFF9B59F5), Color(0xFF7B3FE4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF7B3FE4), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient chargingGradient = LinearGradient(
    colors: [Color(0xFF00FF94), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0F1929), Color(0xFF080B14)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF040810), Color(0xFF060A18), Color(0xFF030508)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Status helpers ────────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return neonGreen;
      case 'busy':
      case 'occupied':
        return amber;
      case 'offline':
      case 'unavailable':
        return red;
      case 'charging':
        return cyan;
      default:
        return textTertiary;
    }
  }

  static Color statusBg(String status) => statusColor(status).withAlpha(25);
}