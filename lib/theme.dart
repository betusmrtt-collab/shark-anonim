import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // PRIMARY - Neon Pink/Magenta
  static const Color primary = Color(0xFFFF2E63);
  static const Color primaryLight = Color(0xFFFF5376);
  static const Color primaryDark = Color(0xFFE51152);
  static const Color onPrimary = Color(0xFFFFFFFF);
  
  // SECONDARY - Electric Cyan
  static const Color secondary = Color(0xFF00C4CC);
  static const Color secondaryLight = Color(0xFF00E5EF);
  static const Color secondaryDark = Color(0xFF00A3AB);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // TERTIARY - Golden/Amber for VIP
  static const Color tertiary = Color(0xFFFFB800);
  static const Color tertiaryLight = Color(0xFFFFD700);
  static const Color onTertiary = Color(0xFF000000);

  // DARK THEME - Background & Surfaces
  static const Color background = Color(0xFF0A0E14);
  static const Color surface = Color(0xFF13181F);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFF1A1F28);
  static const Color surfaceContainer = Color(0xFF1F2631);
  
  // TEXT
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFB0B8C8);
  static const Color onSurfaceMuted = Color(0xFF64748B);

  // BORDERS
  static const Color outline = Color(0xFF2D3748);
  static const Color outlineVariant = Color(0xFF1F2631);

  // ERROR
  static const Color error = Color(0xFFEF4444);
  static const Color onError = Color(0xFFFFFFFF);
  
  // GLOWS
  static Color glowPrimary = const Color(0xFFFF2E63).withOpacity(0.4);
  static Color glowSecondary = const Color(0xFF00C4CC).withOpacity(0.4);
  static Color glowTertiary = const Color(0xFFFFB800).withOpacity(0.3);
}

// SPACING SYSTEM
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 40.0;
  static const double xxl = 64.0;
}

// RADIUS SYSTEM
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double full = 9999.0;
}

// SHADOWS
class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: AppColors.glowPrimary,
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];
  
  static List<BoxShadow> secondaryGlow = [
    BoxShadow(
      color: AppColors.glowSecondary,
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];
  
  static List<BoxShadow> tertiaryGlow = [
    BoxShadow(
      color: AppColors.glowTertiary,
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        error: AppColors.error,
        onError: AppColors.onError,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.sora(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
        ),
        headlineLarge: GoogleFonts.sora(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        headlineMedium: GoogleFonts.sora(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        headlineSmall: GoogleFonts.sora(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        titleLarge: GoogleFonts.sora(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        titleMedium: GoogleFonts.sora(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        titleSmall: GoogleFonts.sora(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceMuted,
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        labelMedium: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceMuted,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceMuted,
        ),
      ),
    );
  }
}
