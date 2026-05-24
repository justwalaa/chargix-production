// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Drop-in Material 3 dark theme for Chargix.
///
/// Usage in app.dart:
///   theme: AppTheme.dark,
abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg1,

    // ── Color scheme ────────────────────────────────────────────────────
    colorScheme: const ColorScheme.dark(
      primary: AppColors.cyan,
      secondary: AppColors.violet,
      surface: AppColors.bg2,
      surfaceContainerHighest: AppColors.bg3,
      onPrimary: AppColors.bg1,
      onSecondary: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      error: AppColors.red,
      onError: AppColors.textPrimary,
    ),

    // ── Typography ──────────────────────────────────────────────────────
    textTheme: const TextTheme(
      displayLarge:  AppTextStyles.displayLg,
      displayMedium: AppTextStyles.displayMd,
      headlineLarge:  AppTextStyles.h1,
      headlineMedium: AppTextStyles.h2,
      headlineSmall:  AppTextStyles.h3,
      titleLarge:     AppTextStyles.h3,
      titleMedium:    AppTextStyles.h4,
      bodyLarge:   AppTextStyles.bodyLg,
      bodyMedium:  AppTextStyles.bodyMd,
      bodySmall:   AppTextStyles.bodySm,
      labelLarge:  AppTextStyles.labelLg,
      labelMedium: AppTextStyles.labelMd,
      labelSmall:  AppTextStyles.labelSm,
    ),

    // ── AppBar ──────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: AppTextStyles.h3.copyWith(letterSpacing: 0.5),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
    ),

    // ── Input decoration ────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg4,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border2, width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border2, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
      labelStyle: AppTextStyles.labelMd,
      hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.red),
      prefixIconColor: AppColors.textTertiary,
      suffixIconColor: AppColors.textTertiary,
    ),

    // ── Elevated button ─────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cyan,
        foregroundColor: AppColors.bg1,
        disabledBackgroundColor: AppColors.bg4,
        disabledForegroundColor: AppColors.textMuted,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: AppTextStyles.button,
        elevation: 0,
        padding:
        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // ── Outlined button ─────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cyan,
        side: const BorderSide(color: AppColors.border2, width: 0.8),
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: AppTextStyles.button,
        padding:
        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // ── Text button ─────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.cyan,
        textStyle: AppTextStyles.buttonSm,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    ),

    // ── Card ────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border1, width: 0.8),
      ),
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),

    // ── Bottom nav bar ───────────────────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: AppColors.cyan,
      unselectedItemColor: AppColors.textMuted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),

    // ── Tab bar ──────────────────────────────────────────────────────────
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.cyan,
      unselectedLabelColor: AppColors.textTertiary,
      indicatorColor: AppColors.cyan,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: AppColors.border1,
      labelStyle: AppTextStyles.labelLg,
      unselectedLabelStyle: AppTextStyles.labelMd,
    ),

    // ── Chip ─────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bg3,
      selectedColor: AppColors.cyan.withAlpha(30),
      side: const BorderSide(color: AppColors.border2, width: 0.8),
      labelStyle: AppTextStyles.labelSm,
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      checkmarkColor: AppColors.cyan,
    ),

    // ── Divider ─────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.border1,
      thickness: 0.8,
      space: 1,
    ),

    // ── Icon ────────────────────────────────────────────────────────────
    iconTheme: const IconThemeData(color: AppColors.cyan, size: 22),

    // ── Snack bar ────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bg3,
      contentTextStyle: AppTextStyles.bodyMd,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border2, width: 0.8),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),

    // ── Dialog ────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border2, width: 0.8),
      ),
      titleTextStyle: AppTextStyles.h2,
      contentTextStyle: AppTextStyles.bodyMd,
      elevation: 0,
    ),

    // ── Bottom sheet ──────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      elevation: 0,
      dragHandleColor: AppColors.border2,
      dragHandleSize: Size(36, 4),
    ),

    // ── Slider ───────────────────────────────────────────────────────────
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.cyan,
      inactiveTrackColor: AppColors.border2,
      thumbColor: AppColors.cyan,
      overlayColor: AppColors.cyan.withAlpha(30),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      trackHeight: 4,
    ),

    // ── Progress indicator ────────────────────────────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.cyan,
      linearTrackColor: AppColors.border2,
      circularTrackColor: AppColors.bg3,
    ),
  );

  // ── Glow button shadow (call site helper) ──────────────────────────────────
  static List<BoxShadow> cyanButtonShadow = [
    BoxShadow(
      color: AppColors.cyanGlow(0.35),
      blurRadius: 24,
      spreadRadius: -6,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> violetButtonShadow = [
    BoxShadow(
      color: AppColors.violetGlow(0.35),
      blurRadius: 24,
      spreadRadius: -6,
      offset: const Offset(0, 8),
    ),
  ];

  /// Premium light theme — same cyan/violet identity on soft cool surfaces.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        colorScheme: const ColorScheme.light(
          primary: AppColors.cyanMid,
          onPrimary: Colors.white,
          secondary: AppColors.violet,
          onSecondary: Colors.white,
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF0A1628),
          surfaceContainerHighest: Color(0xFFE8EEF8),
          onSurfaceVariant: Color(0xFF4A6A8A),
          error: AppColors.red,
          onError: Colors.white,
        ),
        textTheme: TextTheme(
          displayLarge: AppTextStyles.displayLg.copyWith(color: const Color(0xFF0A1628)),
          displayMedium: AppTextStyles.displayMd.copyWith(color: const Color(0xFF0A1628)),
          headlineLarge: AppTextStyles.h1.copyWith(color: const Color(0xFF0A1628)),
          headlineMedium: AppTextStyles.h2.copyWith(color: const Color(0xFF0A1628)),
          headlineSmall: AppTextStyles.h3.copyWith(color: const Color(0xFF0A1628)),
          titleLarge: AppTextStyles.h3.copyWith(color: const Color(0xFF0A1628)),
          titleMedium: AppTextStyles.h4.copyWith(color: const Color(0xFF0A1628)),
          bodyLarge: AppTextStyles.bodyLg.copyWith(color: const Color(0xFF1A2D45)),
          bodyMedium: AppTextStyles.bodyMd.copyWith(color: const Color(0xFF1A2D45)),
          bodySmall: AppTextStyles.bodySm.copyWith(color: const Color(0xFF4A6A8A)),
          labelLarge: AppTextStyles.labelLg.copyWith(color: const Color(0xFF0A1628)),
          labelMedium: AppTextStyles.labelMd.copyWith(color: const Color(0xFF4A6A8A)),
          labelSmall: AppTextStyles.labelSm.copyWith(color: const Color(0xFF4A6A8A)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF0A1628),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: AppTextStyles.h3.copyWith(
            letterSpacing: 0.5,
            color: const Color(0xFF0A1628),
          ),
          iconTheme: const IconThemeData(
            color: Color(0xFF4A6A8A),
            size: 22,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD0DCEF), width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD0DCEF), width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.cyanMid, width: 1.5),
          ),
          labelStyle: AppTextStyles.labelMd.copyWith(color: const Color(0xFF4A6A8A)),
          hintStyle: AppTextStyles.bodyMd.copyWith(color: const Color(0xFF8AAAC8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cyanMid,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: AppTextStyles.button,
            elevation: 0,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE0E8F5), width: 0.8),
          ),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE0E8F5),
          thickness: 0.8,
        ),
        iconTheme: const IconThemeData(color: AppColors.cyanMid, size: 22),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE0E8F5), width: 0.8),
          ),
          titleTextStyle: AppTextStyles.h2.copyWith(color: const Color(0xFF0A1628)),
          contentTextStyle: AppTextStyles.bodyMd.copyWith(color: const Color(0xFF1A2D45)),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.cyanMid,
        ),
      );
}