import 'package:flutter/material.dart';

/// Palette de l'app. Les couleurs dépendantes du thème sont **mutables** :
/// `AppColors.setMode(light)` bascule toute la palette (clair / sombre), puis
/// l'app est reconstruite. Les couleurs « vives » (muscles, statuts) sont
/// identiques dans les deux modes.
class AppColors {
  AppColors._();

  static bool isLight = false;

  // ── Couleurs dépendantes du thème (mutables) ──────────────────
  static Color bg = _dBg;
  static Color bgCard = _dBgCard;
  static Color bgCardElevated = _dBgCardElevated;
  static Color bgSurface = _dBgSurface;
  static Color accent = _dAccent;
  static Color accentLight = _dAccentLight;
  static Color accentDark = _dAccentDark;
  static Color accentGlow = _dAccentGlow;
  static Color secondary = _dSecondary;
  static Color secondaryGlow = _dSecondaryGlow;
  static Color textPrimary = _dTextPrimary;
  static Color textSecondary = _dTextSecondary;
  static Color textMuted = _dTextMuted;
  static Color border = _dBorder;
  static Color borderLight = _dBorderLight;

  /// Bascule toute la palette. À appeler avant de reconstruire l'app.
  static void setMode(bool light) {
    isLight = light;
    bg = light ? _lBg : _dBg;
    bgCard = light ? _lBgCard : _dBgCard;
    bgCardElevated = light ? _lBgCardElevated : _dBgCardElevated;
    bgSurface = light ? _lBgSurface : _dBgSurface;
    accent = light ? _lAccent : _dAccent;
    accentLight = light ? _lAccentLight : _dAccentLight;
    accentDark = light ? _lAccentDark : _dAccentDark;
    accentGlow = light ? _lAccentGlow : _dAccentGlow;
    secondary = light ? _lSecondary : _dSecondary;
    secondaryGlow = light ? _lSecondaryGlow : _dSecondaryGlow;
    textPrimary = light ? _lTextPrimary : _dTextPrimary;
    textSecondary = light ? _lTextSecondary : _dTextSecondary;
    textMuted = light ? _lTextMuted : _dTextMuted;
    border = light ? _lBorder : _dBorder;
    borderLight = light ? _lBorderLight : _dBorderLight;
  }

  // ── Valeurs SOMBRES ───────────────────────────────────────────
  static const _dBg = Color(0xFF0A0A0F);
  static const _dBgCard = Color(0xFF13131A);
  static const _dBgCardElevated = Color(0xFF1C1C26);
  static const _dBgSurface = Color(0xFF1E1E2A);
  static const _dAccent = Color(0xFF9B7FFD);
  static const _dAccentLight = Color(0xFFB79DFF);
  static const _dAccentDark = Color(0xFF7C5CFC);
  static const _dAccentGlow = Color(0x339B7FFD);
  static const _dSecondary = Color(0xFF00D4FF);
  static const _dSecondaryGlow = Color(0x3300D4FF);
  static const _dTextPrimary = Color(0xFFFFFFFF);
  static const _dTextSecondary = Color(0xFFB0B0C8);
  static const _dTextMuted = Color(0xFF8A8AAE);
  static const _dBorder = Color(0xFF2A2A3A);
  static const _dBorderLight = Color(0xFF3A3A4E);

  // ── Valeurs CLAIRES ───────────────────────────────────────────
  static const _lBg = Color(0xFFF2F2F6);
  static const _lBgCard = Color(0xFFFFFFFF);
  static const _lBgCardElevated = Color(0xFFECECF2);
  static const _lBgSurface = Color(0xFFE6E6EE);
  static const _lAccent = Color(0xFF6B4EEA);
  static const _lAccentLight = Color(0xFF8A6EF5);
  static const _lAccentDark = Color(0xFF553BC4);
  static const _lAccentGlow = Color(0x226B4EEA);
  static const _lSecondary = Color(0xFF0090B8);
  static const _lSecondaryGlow = Color(0x220090B8);
  static const _lTextPrimary = Color(0xFF16161F);
  static const _lTextSecondary = Color(0xFF4C4C63);
  static const _lTextMuted = Color(0xFF7A7A92);
  static const _lBorder = Color(0xFFDCDCE6);
  static const _lBorderLight = Color(0xFFC7C7D4);

  // ── Couleurs vives (identiques clair / sombre) ────────────────
  // Muscle groups
  static const Color chest = Color(0xFFFF6B6B);
  static const Color back = Color(0xFF4ECDC4);
  static const Color shoulders = Color(0xFFFFE66D);
  static const Color arms = Color(0xFF9B7FFD);
  static const Color legs = Color(0xFF56CFE1);
  static const Color core = Color(0xFFFF9A3C);
  static const Color cardio = Color(0xFFFF6584);

  // Status
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFFF5757);

  // Difficulty
  static const Color easy = Color(0xFF4ADE80);
  static const Color medium = Color(0xFFFBBF24);
  static const Color hard = Color(0xFFFF5757);
}
