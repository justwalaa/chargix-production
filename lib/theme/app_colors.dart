import 'package:flutter/material.dart';

/// Soft premium EV ecosystem palette (light-first, luxury minimal).
abstract final class AppColors {
  // Brand — soft teal + iris (reference-inspired, not flat green)
  static const Color mint = Color(0xFF5EEAD4);
  static const Color teal = Color(0xFF2DD4BF);
  static const Color tealDeep = Color(0xFF14B8A6);
  static const Color iris = Color(0xFF818CF8);
  static const Color irisSoft = Color(0xFFC7D2FE);

  // Neutrals
  static const Color ink = Color(0xFF0F172A);
  static const Color inkMuted = Color(0xFF64748B);
  static const Color pearl = Color(0xFFF8FAFC);
  static const Color mist = Color(0xFFF1F5F9);
  static const Color cloud = Color(0xFFFFFFFF);

  // Surfaces dark
  static const Color night = Color(0xFF0B1220);
  static const Color nightCard = Color(0xFF151D2E);

  // Semantic
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);
  static const Color logistics = Color(0xFFF59E0B);

  // Legacy aliases
  static const Color primary = teal;
  static const Color secondary = iris;
  static const Color electric = mint;
  static const Color electricDark = tealDeep;
  static const Color navy = ink;
  static const Color surfaceLight = pearl;
  static const Color surfaceCardLight = cloud;
  static const Color surfaceDark = night;
  static const Color surfaceCardDark = nightCard;
  static const Color onPrimary = cloud;
}
