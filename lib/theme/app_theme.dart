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

  // ── Light theme green palette ──────────────────────────────────────────────
  static const _lgPrimary        = Color(0xFF22C55E); // green-500
  static const _lgPrimaryDark    = Color(0xFF16A34A); // green-600
  static const _lgPrimaryContainer = Color(0xFFDCFCE7); // green-100
  static const _lgOnPrimaryContainer = Color(0xFF14532D); // green-900
  static const _lgInk            = Color(0xFF101828);
  static const _lgSlate          = Color(0xFF6B7280);
  static const _lgBorder         = Color(0xFFE5E7EB);
  static const _lgCanvas         = Color(0xFFF8F9FA);

  /// Premium light theme — clean/calm Chargix green on soft off-white canvas.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: _lgCanvas,
        colorScheme: const ColorScheme.light(
          primary: _lgPrimary,
          onPrimary: Colors.white,
          primaryContainer: _lgPrimaryContainer,
          onPrimaryContainer: _lgOnPrimaryContainer,
          secondary: _lgPrimaryDark,
          onSecondary: Colors.white,
          surface: Color(0xFFFFFFFF),
          onSurface: _lgInk,
          surfaceContainerHighest: Color(0xFFF3F4F6),
          onSurfaceVariant: _lgSlate,
          error: Color(0xFFDC2626),
          onError: Colors.white,
        ),
        textTheme: TextTheme(
          displayLarge: AppTextStyles.displayLg.copyWith(color: _lgInk),
          displayMedium: AppTextStyles.displayMd.copyWith(color: _lgInk),
          headlineLarge: AppTextStyles.h1.copyWith(color: _lgInk),
          headlineMedium: AppTextStyles.h2.copyWith(color: _lgInk),
          headlineSmall: AppTextStyles.h3.copyWith(color: _lgInk),
          titleLarge: AppTextStyles.h3.copyWith(color: _lgInk),
          titleMedium: AppTextStyles.h4.copyWith(color: _lgInk),
          bodyLarge: AppTextStyles.bodyLg.copyWith(color: _lgInk),
          bodyMedium: AppTextStyles.bodyMd.copyWith(color: _lgInk),
          bodySmall: AppTextStyles.bodySm.copyWith(color: _lgSlate),
          labelLarge: AppTextStyles.labelLg.copyWith(color: _lgInk),
          labelMedium: AppTextStyles.labelMd.copyWith(color: _lgSlate),
          labelSmall: AppTextStyles.labelSm.copyWith(color: _lgSlate),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: _lgInk,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: AppTextStyles.h3.copyWith(
            letterSpacing: 0.3,
            color: _lgInk,
          ),
          iconTheme: const IconThemeData(color: _lgSlate, size: 22),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _lgBorder, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _lgBorder, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _lgPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
          ),
          labelStyle: AppTextStyles.labelMd.copyWith(color: _lgSlate),
          hintStyle: AppTextStyles.bodyMd.copyWith(color: const Color(0xFFD1D5DB)),
          prefixIconColor: _lgSlate,
          suffixIconColor: _lgSlate,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _lgPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE5E7EB),
            disabledForegroundColor: _lgSlate,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: AppTextStyles.button,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _lgPrimary,
            side: const BorderSide(color: _lgBorder, width: 1),
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: AppTextStyles.button,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _lgPrimary,
            textStyle: AppTextStyles.buttonSm,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _lgBorder, width: 0.8),
          ),
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF3F4F6),
          selectedColor: _lgPrimaryContainer,
          side: const BorderSide(color: _lgBorder, width: 0.8),
          labelStyle: AppTextStyles.labelSm.copyWith(color: _lgInk),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          checkmarkColor: _lgPrimary,
        ),
        dividerTheme: const DividerThemeData(
          color: _lgBorder,
          thickness: 0.8,
          space: 1,
        ),
        iconTheme: const IconThemeData(color: _lgPrimary, size: 22),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          elevation: 0,
          dragHandleColor: _lgBorder,
          dragHandleSize: Size(36, 4),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: _lgBorder, width: 0.8),
          ),
          titleTextStyle: AppTextStyles.h2.copyWith(color: _lgInk),
          contentTextStyle: AppTextStyles.bodyMd.copyWith(color: _lgInk),
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _lgInk,
          contentTextStyle: AppTextStyles.bodyMd.copyWith(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: _lgPrimary,
          inactiveTrackColor: _lgBorder,
          thumbColor: _lgPrimary,
          overlayColor: _lgPrimary.withAlpha(30),
          trackHeight: 4,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _lgPrimary,
          linearTrackColor: _lgBorder,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: _lgPrimary,
          unselectedLabelColor: _lgSlate,
          indicatorColor: _lgPrimary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: _lgBorder,
          labelStyle: AppTextStyles.labelLg,
          unselectedLabelStyle: AppTextStyles.labelMd,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: _lgPrimary,
          unselectedItemColor: _lgSlate,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      );
}