import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFFF97316);
  static const Color primaryDark = Color(0xFFEA6A0A);
  static const Color primaryLight = Color(0xFFFFA64D);

  // Background (dark-first)
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceVariant = Color(0xFF242424);
  static const Color card = Color(0xFF1E1E1E);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textHint = Color(0xFF666666);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Map
  static const Color mapBackground = Color(0xFF1A1A2E);

  // Divider / Border
  static const Color border = Color(0xFF2A2A2A);
  static const Color divider = Color(0xFF2A2A2A);

  // Wallet
  static const Color walletGradientStart = Color(0xFF1E1E1E);
  static const Color walletGradientEnd = Color(0xFF2D1A0A);

  // Shadows
  static final Color shadowColor = Colors.black.withValues(alpha: 0.4);

  // Status badges
  static const Color statusOpen = Color(0xFF22C55E);
  static const Color statusInProgress = Color(0xFFF97316);
  static const Color statusCompleted = Color(0xFF3B82F6);
  static const Color statusBlocked = Color(0xFFEF4444);
}
