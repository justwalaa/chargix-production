import 'package:flutter/material.dart';

/// Soft premium gradients for heroes, auth, and cards.
abstract final class AppGradients {
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4ADE80), // green-400
      Color(0xFF22C55E), // green-500
      Color(0xFF16A34A), // green-600
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient heroLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFEFFDFB),
      Color(0xFFF8FAFC),
      Color(0xFFFFFFFF),
    ],
  );

  static const LinearGradient heroDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B1220),
      Color(0xFF111827),
      Color(0xFF1E293B),
    ],
  );

  static const LinearGradient cardSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FAFC),
    ],
  );

  static const LinearGradient mapOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xCCFFFFFF),
      Color(0x00FFFFFF),
    ],
  );

  static LinearGradient heroLightContext(BuildContext context) => heroLight;

  static LinearGradient hero(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? heroDark : heroLight;
  }
}
