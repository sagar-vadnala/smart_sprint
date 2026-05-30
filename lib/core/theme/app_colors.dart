import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const brand = Color(0xFF6C47FF);
  static const brandDark = Color(0xFF5535CC);
  static const brandLight = Color(0xFF8B6FFF);
  static const brandSurface = Color(0xFFF0ECFF);

  // Accent / CTA
  static const accent = Color(0xFFFF6B35);
  static const accentLight = Color(0xFFFF8C5A);

  // Status
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Light theme neutrals
  static const lightBg = Color(0xFFFAFAFA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE4E4E7);
  static const lightText = Color(0xFF09090B);
  static const lightTextMuted = Color(0xFF71717A);
  static const lightFill = Color(0xFFF4F4F5);

  // Dark theme neutrals
  static const darkBg = Color(0xFF09090B);
  static const darkSurface = Color(0xFF18181B);
  static const darkBorder = Color(0xFF27272A);
  static const darkText = Color(0xFFFAFAFA);
  static const darkTextMuted = Color(0xFFA1A1AA);
  static const darkFill = Color(0xFF27272A);

  // ── Depth / ambient / glass tokens ──────────────────────────────────────────
  // Slightly tinted bases for the ambient background — reads more "crafted"
  // than pure black / flat white.
  static const darkBase = Color(0xFF0A0A0F);
  static const lightBase = Color(0xFFF6F7FB);
  // Elevated surface — top of a card gradient.
  static const darkSurfaceHigh = Color(0xFF1F1F27);
  static const lightSurfaceHigh = Color(0xFFFFFFFF);

  // Brand gradient (logo, hero cards, primary CTAs).
  static const brandGradient = [Color(0xFF8B6FFF), brand, Color(0xFF5535CC)];

  // Ambient glow accents for the backdrop.
  static const glowViolet = Color(0xFF6C47FF);
  static const glowTeal = Color(0xFF14B8A6);
  static const glowCoral = Color(0xFFFF6B35);

  // Onboarding section backgrounds
  static const ob1 = Color(0xFFC2410C); // bold orange — action & energy
  static const ob2 = Color(0xFF14532D); // deep emerald — growth & focus
  static const ob3 = Color(0xFF09090B); // near-black — team & authority

  // Task label colors
  static const taskRed = Color(0xFFFCA5A5);
  static const taskAmber = Color(0xFFFCD34D);
  static const taskGreen = Color(0xFF86EFAC);
  static const taskBlue = Color(0xFF93C5FD);
  static const taskPurple = Color(0xFFC4B5FD);
}
