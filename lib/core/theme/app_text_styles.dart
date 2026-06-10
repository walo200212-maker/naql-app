import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Cairo — Arabic / general UI text
  static const String _cairo = 'Cairo';

  static const TextStyle display = TextStyle(
    fontFamily: _cairo, fontSize: 32, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, height: 1.2,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: _cairo, fontSize: 26, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _cairo, fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _cairo, fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _cairo, fontSize: 16, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary, height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _cairo, fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.5,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: _cairo, fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _cairo, fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _cairo, fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 0.8, height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _cairo, fontSize: 16, fontWeight: FontWeight.w700,
    color: Colors.white, height: 1.2,
  );

  // Poppins — numbers, prices, balances (English/numeric displays)
  static TextStyle get priceLarge => GoogleFonts.poppins(
    fontSize: 36, fontWeight: FontWeight.w800,
    color: AppColors.primary, height: 1.0,
  );

  static TextStyle get price => GoogleFonts.poppins(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: AppColors.primary, height: 1.1,
  );

  static TextStyle get priceMedium => GoogleFonts.poppins(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.primary, height: 1.1,
  );

  static TextStyle get wallet => GoogleFonts.poppins(
    fontSize: 40, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, height: 1.0,
  );

  static TextStyle get numericDisplay => GoogleFonts.poppins(
    fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.0,
  );

  static TextStyle get numericSmall => GoogleFonts.poppins(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
