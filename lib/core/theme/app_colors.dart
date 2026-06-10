import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary        = Color(0xFFF97316);
  static const Color primaryDark    = Color(0xFFEA6C0A);
  static const Color primaryLight   = Color(0xFFFFA64D);
  static const Color primaryGlow    = Color(0x33F97316);

  // Backgrounds
  static const Color background     = Color(0xFF0F0F0F);
  static const Color surface        = Color(0xFF1A1A1A);
  static const Color surfaceHigh    = Color(0xFF242424);
  static const Color surfaceVariant = Color(0xFF242424);
  static const Color surfaceBorder  = Color(0xFF2E2E2E);
  static const Color card           = Color(0xFF1A1A1A);

  // Text
  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFF9A9A9A);
  static const Color textHint       = Color(0xFF555555);

  // Status
  static const Color success        = Color(0xFF22C55E);
  static const Color successGlow    = Color(0x2222C55E);
  static const Color error          = Color(0xFFEF4444);
  static const Color errorGlow      = Color(0x22EF4444);
  static const Color warning        = Color(0xFFF97316);
  static const Color info           = Color(0xFF3B82F6);

  // Borders & Dividers
  static const Color border         = Color(0xFF2E2E2E);
  static const Color divider        = Color(0xFF1E1E1E);

  // Shimmer
  static const Color shimmerBase    = Color(0xFF1A1A1A);
  static const Color shimmerHigh    = Color(0xFF2A2A2A);

  // Map
  static const Color mapBackground  = Color(0xFF1A1A2E);

  // Wallet gradient
  static const Color walletGradientStart = Color(0xFF1E1E1E);
  static const Color walletGradientEnd   = Color(0xFF2D1A0A);

  // Status badges
  static const Color statusOpen       = Color(0xFF22C55E);
  static const Color statusInProgress = Color(0xFFF97316);
  static const Color statusCompleted  = Color(0xFF3B82F6);
  static const Color statusBlocked    = Color(0xFFEF4444);

  static final Color shadowColor = Colors.black.withValues(alpha: 0.4);
}
