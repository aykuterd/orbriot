import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Orbitron — başlıklar, logo, menü
  static TextStyle get displayLarge => GoogleFonts.orbitron(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        color: AppColors.foreground,
        letterSpacing: 2,
      );

  static TextStyle get displayMedium => GoogleFonts.orbitron(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
        letterSpacing: 1.5,
      );

  static TextStyle get headlineLarge => GoogleFonts.orbitron(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
        letterSpacing: 1,
      );

  static TextStyle get headlineMedium => GoogleFonts.orbitron(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      );

  // JetBrains Mono — sayılar, HUD, skor
  static TextStyle get scoreDisplay => GoogleFonts.jetBrainsMono(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
        letterSpacing: 2,
      );

  static TextStyle get hudLabel => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
        letterSpacing: 1.5,
      );

  static TextStyle get hudValue => GoogleFonts.jetBrainsMono(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
        letterSpacing: 1,
      );

  static TextStyle get brickHp => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      );

  static TextStyle get bodyMedium => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.foreground,
      );

  static TextStyle get bodySmall => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      );

  static TextStyle get button => GoogleFonts.orbitron(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
        letterSpacing: 1.5,
      );
}
