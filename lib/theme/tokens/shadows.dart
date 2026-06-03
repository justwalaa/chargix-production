// lib/theme/tokens/shadows.dart
//
// VOLTA elevation shadows — clean, precise, no neon glow.
//
// All shadows use the ink color (0xFF101828) at very low opacity, producing
// a warm-neutral shadow that works on both white and light-gray surfaces.
// The "primary" shadow is the only accent-colored one, reserved for primary
// buttons and the active FAB to make them feel "lifted and important."
import 'package:flutter/material.dart';

abstract final class AppShadows {
  // ── Elevation scale ────────────────────────────────────────────────────────

  /// Barely-there — hairline cards on scaffold
  static List<BoxShadow> get sm => const [
        BoxShadow(
          color: Color.fromRGBO(16, 24, 40, 0.04),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color.fromRGBO(16, 24, 40, 0.02),
          blurRadius: 1,
          offset: Offset(0, 0),
        ),
      ];

  /// Standard card shadow
  static List<BoxShadow> get md => const [
        BoxShadow(
          color: Color.fromRGBO(16, 24, 40, 0.04),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
        BoxShadow(
          color: Color.fromRGBO(16, 24, 40, 0.06),
          blurRadius: 10,
          offset: Offset(0, 6),
        ),
      ];

  /// Focused / hovered card, FAB resting
  static List<BoxShadow> get lg => const [
        BoxShadow(
          color: Color.fromRGBO(16, 24, 40, 0.04),
          blurRadius: 6,
          offset: Offset(0, 4),
        ),
        BoxShadow(
          color: Color.fromRGBO(16, 24, 40, 0.08),
          blurRadius: 20,
          offset: Offset(0, 12),
        ),
      ];

  /// Bottom sheet, modal overlay
  static List<BoxShadow> get xl => const [
        BoxShadow(
          color: Color.fromRGBO(16, 24, 40, 0.06),
          blurRadius: 12,
          offset: Offset(0, 8),
        ),
        BoxShadow(
          color: Color.fromRGBO(16, 24, 40, 0.10),
          blurRadius: 40,
          offset: Offset(0, 24),
        ),
      ];

  /// Primary button / active FAB — subtle Volta Red warmth
  static List<BoxShadow> get primary => const [
        BoxShadow(
          color: Color.fromRGBO(192, 57, 43, 0.20),
          blurRadius: 16,
          spreadRadius: -4,
          offset: Offset(0, 6),
        ),
        BoxShadow(
          color: Color.fromRGBO(192, 57, 43, 0.08),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ];

  /// Success state (e.g. booking confirmed banner)
  static List<BoxShadow> get success => const [
        BoxShadow(
          color: Color.fromRGBO(2, 122, 72, 0.16),
          blurRadius: 16,
          spreadRadius: -4,
          offset: Offset(0, 6),
        ),
      ];

  // Backward-compat for call sites that used AppTheme.cyanButtonShadow
  static List<BoxShadow> get cyanButton  => primary;
  static List<BoxShadow> get violetButton => [
        BoxShadow(
          color: Color.fromRGBO(71, 84, 103, 0.16),
          blurRadius: 16,
          spreadRadius: -4,
          offset: Offset(0, 6),
        ),
      ];
}
