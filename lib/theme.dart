import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF000000);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF131B2E);
  static const Color onPrimaryContainer = Color(0xFF7C839B);
  static const Color primaryFixed = Color(0xFFDAE2FD);
  static const Color primaryFixedDim = Color(0xFFBEC6E0);
  static const Color onPrimaryFixed = Color(0xFF131B2E);
  static const Color onPrimaryFixedVariant = Color(0xFF3F465C);

  // Secondary Colors
  static const Color secondary = Color(0xFF00687A);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF57DFFE);
  static const Color onSecondaryContainer = Color(0xFF006172);
  static const Color secondaryFixed = Color(0xFFACEDFF);
  static const Color secondaryFixedDim = Color(0xFF4CD7F6);
  static const Color onSecondaryFixed = Color(0xFF001F26);
  static const Color onSecondaryFixedVariant = Color(0xFF004E5C);

  // Tertiary Colors
  static const Color tertiary = Color(0xFF000000);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF40000D);
  static const Color onTertiaryContainer = Color(0xFFF23D5C);
  static const Color tertiaryFixed = Color(0xFFFFDADB);
  static const Color tertiaryFixedDim = Color(0xFFFFB2B7);
  static const Color onTertiaryFixed = Color(0xFF40000D);
  static const Color onTertiaryFixedVariant = Color(0xFF92002A);

  // Surface Colors
  static const Color surface = Color(0xFFF8F9FF);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color surfaceVariant = Color(0xFFD3E4FE);
  static const Color onSurfaceVariant = Color(0xFF45464D);
  static const Color surfaceDim = Color(0xFFCBDBF5);
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);

  // Background
  static const Color background = Color(0xFFF8F9FF);
  static const Color onBackground = Color(0xFF0B1C30);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Outline
  static const Color outline = Color(0xFF76777D);
  static const Color outlineVariant = Color(0xFFC6C6CD);

  // Inverse
  static const Color inverseSurface = Color(0xFF213145);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);
  static const Color inversePrimary = Color(0xFFBEC6E0);

  // Surface Tint
  static const Color surfaceTint = Color(0xFF565E74);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 56,
          height: 1.14,
          letterSpacing: -1.68,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 36,
          height: 1.22,
          letterSpacing: -0.72,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          height: 1.33,
          letterSpacing: -0.24,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 18,
          height: 1.56,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 15,
          height: 1.6,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 13,
          height: 1.38,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 14,
          height: 1.43,
          letterSpacing: 0.14,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        labelMedium: GoogleFonts.manrope(
          fontSize: 12,
          height: 1.33,
          letterSpacing: 0.24,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 10,
          height: 1.4,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}
