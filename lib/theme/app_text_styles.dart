// lib/core/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Complete typography scale for Chargix.
///
/// Scale: display → heading → body → label → caption
/// Brand elements use wide letter-spacing; body uses tight/normal.
abstract final class AppTextStyles {
  // ── Display ───────────────────────────────────────────────────────────────
  static const TextStyle displayLg = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    color: AppColors.textPrimary,
    height: 1.05,
  );

  static const TextStyle displayMd = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  // ── Headings ──────────────────────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ── Body ──────────────────────────────────────────────────────────────────
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.55,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ── Labels ────────────────────────────────────────────────────────────────
  static const TextStyle labelLg = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMd = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
    color: AppColors.textTertiary,
  );

  // ── Captions ──────────────────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  static const TextStyle captionMuted = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const TextStyle brand = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: 8.0,
    color: AppColors.textPrimary,
    height: 1.0,
  );

  static const TextStyle brandSm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 4.0,
    color: AppColors.cyan,
  );

  // ── Numeric / Stats ───────────────────────────────────────────────────────
  static const TextStyle statLg = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
    height: 1.0,
  );

  static const TextStyle statMd = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  static const TextStyle statSm = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  // ── Buttons ───────────────────────────────────────────────────────────────
  static const TextStyle buttonLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonSm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // ── Tab / Nav ─────────────────────────────────────────────────────────────
  static const TextStyle navLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.2,
  );

  // ── Convenience: colored variants ─────────────────────────────────────────
  static TextStyle get h1Cyan => h1.copyWith(color: AppColors.cyan);
  static TextStyle get h2Cyan => h2.copyWith(color: AppColors.cyan);
  static TextStyle get bodyCyan => bodyMd.copyWith(color: AppColors.cyan);
  static TextStyle get bodyPrimary => bodyMd.copyWith(color: AppColors.textPrimary);
}