import 'package:flutter/material.dart';

/// Progcap Design System — TechnoYuga Brand Colors
/// Primary: #0535E9 (Electric Blue)  |  Accent: #F10BF8 (Magenta)
class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF0535E9);
  static const Color primaryDark   = Color(0xFF0426C0);
  static const Color primaryLight  = Color(0xFF3A5FFF);
  static const Color accent        = Color(0xFFF10BF8);
  static const Color accentDark    = Color(0xFFC508CC);

  // ── Gradient ──────────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFF10BF8), Color(0xFF0535E9)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0535E9), Color(0xFF0A1A8A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0535E9), Color(0xFF3A5FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success       = Color(0xFF00B96B);
  static const Color successLight  = Color(0xFFE6FFF5);
  static const Color warning       = Color(0xFFFA8C16);
  static const Color warningLight  = Color(0xFFFFF7E6);
  static const Color error         = Color(0xFFFF4D4F);
  static const Color errorLight    = Color(0xFFFFF1F0);
  static const Color info          = Color(0xFF1677FF);
  static const Color infoLight     = Color(0xFFE6F4FF);

  // ── AI / Purple ───────────────────────────────────────────────────────────
  static const Color aiPurple      = Color(0xFF7C3AED);
  static const Color aiPurpleLight = Color(0xFFEDE9FE);

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color background    = Color(0xFFF4F6FF);   // cool blue tint
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color card          = Color(0xFFFFFFFF);
  static const Color darkNavy      = Color(0xFF080E28);   // TechnoYuga navbar

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0A0F1E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled  = Color(0xFFB0BAD3);
  static const Color textOnDark    = Color(0xFFFFFFFF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders & Dividers ────────────────────────────────────────────────────
  static const Color border        = Color(0xFFE4E9FF);   // blue-tinted
  static const Color divider       = Color(0xFFEEF1FF);
  static const Color borderDark    = Color(0xFFC7D2FE);

  // ── States ────────────────────────────────────────────────────────────────
  static const Color hoverBlue     = Color(0x0F0535E9);   // 6% opacity
  static const Color selectedBlue  = Color(0x1F0535E9);   // 12% opacity
  static const Color overlay       = Color(0xCC080E28);   // 80% dark

  // ── Stage Colors ──────────────────────────────────────────────────────────
  static const Color stageAssigned    = Color(0xFF1677FF);
  static const Color stageInProgress  = Color(0xFFFA8C16);
  static const Color stageKyc        = Color(0xFF7C3AED);
  static const Color stageSanctioned  = Color(0xFF00B96B);
  static const Color stageDisbursed   = Color(0xFF0535E9);
  static const Color stageUrgent      = Color(0xFFFF4D4F);
  static const Color stageStuck       = Color(0xFFFF7A00);

  // ── Utility ───────────────────────────────────────────────────────────────
  static const Color transparent   = Colors.transparent;
  static const Color white         = Colors.white;
  static const Color black         = Colors.black;

  // ── Backward-Compatible Aliases ───────────────────────────────────────────
  // Old color names used by existing widgets — mapped to new design tokens
  static const Color brandBlue    = primary;
  static const Color darkBlue     = primaryDark;
  static const Color deepNavy     = darkNavy;
  static const Color accentGreen  = success;
  static const Color softBlueGrey = Color(0xFFF4F6FF); // = background
  static const Color lightBlue    = Color(0xFFE6EEFF);

  // ── Stage helper ──────────────────────────────────────────────────────────
  static Color forStage(String stage) {
    switch (stage.toUpperCase()) {
      case 'ASSIGNED':          return stageAssigned;
      case 'IN_PROGRESS':       return stageInProgress;
      case 'KYC_SUBMITTED':     return stageKyc;
      case 'CREDIT_ASSESSMENT': return aiPurple;
      case 'SANCTIONED':        return stageSanctioned;
      case 'DISBURSED':         return stageDisbursed;
      default:                  return textSecondary;
    }
  }
}
