import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: AppColors.foreground,
          onSecondary: AppColors.background,
          onSurface: AppColors.foreground,
          onError: AppColors.foreground,
        ),
        textTheme: GoogleFonts.jetBrainsMonoTextTheme(
          const TextTheme(
            bodyLarge: TextStyle(color: AppColors.foreground),
            bodyMedium: TextStyle(color: AppColors.foreground),
            bodySmall: TextStyle(color: AppColors.muted),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.foreground,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
        splashColor: AppColors.primary.withAlpha(40),
        highlightColor: Colors.transparent,
      );
}
