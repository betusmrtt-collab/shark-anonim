import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified App Theme - Birleştirilmiş Tema Sistemi
/// Tüm sayfalar bu renkleri ve stilleri kullanmalı

class AppColors {
  // PRIMARY - Ana Marka Rengi (CTA Butonlar, Önemli Öğeler)
  static const Color primary = Color(0xFFFF5E00); // Turuncu - Enerji, Flört
  static const Color primaryLight = Color(0xFFFF7B2E);
  static const Color primaryDark = Color(0xFFE54D00);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // SECONDARY - İkincil Vurgu (Linkler, İkonlar, Bilgilendirme)
  static const Color secondary = Color(0xFF06B6D4); // Sky Blue/Cyan
  static const Color secondaryLight = Color(0xFF00E5FF); // Neon cyan
  static const Color secondaryDark = Color(0xFF00687A);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // ACCENT - Aksan Rengi (Vurgular, Hover States)
  static const Color accent = Color(0xFFFF4D6D); // Pink - Flört hissi
  static const Color accentLight = Color(0xFFFF6B8A);
  static const Color onAccent = Color(0xFFFFFFFF);

  // TERTIARY - VIP/Özel Özellikler (Hediye, Premium)
  static const Color tertiary = Color(0xFFFFB800); // Altın
  static const Color tertiaryLight = Color(0xFFFFD700);
  static const Color tertiaryDark = Color(0xFFE5A500);
  static const Color onTertiary = Color(0xFF000000);

  // SUCCESS - Başarı Mesajları
  static const Color success = Color(0xFF10B981);
  static const Color onSuccess = Color(0xFFFFFFFF);

  // WARNING - Uyarılar
  static const Color warning = Color(0xFFF59E0B);
  static const Color onWarning = Color(0xFF000000);

  // ERROR - Hata Mesajları
  static const Color error = Color(0xFFFF6B6B);
  static const Color errorDark = Color(0xFFFF4444);
  static const Color onError = Color(0xFFFFFFFF);

  // BACKGROUND - Light Mode (Varsayılan)
  static const Color background = Color(0xFFF8FAFC); // Açık gri-mavi
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color surfaceDim = Color(0xFFE2E8F0);

  // BACKGROUND - Dark Mode (İsteğe bağlı)
  static const Color backgroundDark = Color(0xFF0A0E14);
  static const Color surfaceDark = Color(0xFF13181F);
  static const Color surfaceBrightDark = Color(0xFF1F2631);
  static const Color surfaceDimDark = Color(0xFF1A1F28);

  // TEXT - Light Mode
  static const Color onBackground = Color(0xFF0B1C30); // Koyu mavi-siyah
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF475569);
  static const Color onSurfaceMuted = Color(0xFF64748B);
  static const Color onSurfaceLight = Color(0xFF94A3B8);

  // TEXT - Dark Mode
  static const Color onBackgroundDark = Color(0xFFFFFFFF);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color onSurfaceVariantDark = Color(0xFFB0B8C8);

  // BORDERS
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineVariant = Color(0xFFCBD5E1);
  static const Color outlineDark = Color(0xFF2D3748);

  // GLOWS & SHADOWS
  static Color glowPrimary = const Color(0xFFFF5E00).withOpacity(0.3);
  static Color glowSecondary = const Color(0xFF06B6D4).withOpacity(0.25);
  static Color glowAccent = const Color(0xFFFF4D6D).withOpacity(0.25);
  static Color glowTertiary = const Color(0xFFFFB800).withOpacity(0.3);
}

// SPACING SYSTEM
class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

// RADIUS SYSTEM
class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double full = 9999.0;
}

// ELEVATION (Shadow) SYSTEM
class AppElevation {
  // Subtle shadow for cards
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Medium shadow for elevated elements
  static List<BoxShadow> elevated = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // Strong shadow for modals and dialogs
  static List<BoxShadow> modal = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Primary glow for CTA buttons
  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: AppColors.glowPrimary,
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 6),
    ),
  ];

  // Secondary glow for info/links
  static List<BoxShadow> secondaryGlow = [
    BoxShadow(
      color: AppColors.glowSecondary,
      blurRadius: 20,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
  ];

  // Accent glow for special elements
  static List<BoxShadow> accentGlow = [
    BoxShadow(
      color: AppColors.glowAccent,
      blurRadius: 24,
      spreadRadius: 2,
      offset: const Offset(0, 6),
    ),
  ];

  // Tertiary glow for VIP/Premium
  static List<BoxShadow> tertiaryGlow = [
    BoxShadow(
      color: AppColors.glowTertiary,
      blurRadius: 30,
      spreadRadius: 2,
      offset: const Offset(0, 8),
    ),
  ];
}

// TYPOGRAPHY SYSTEM
class AppTypography {
  // Display - Hero text (48px+)
  static TextStyle display = GoogleFonts.bricolageGrotesque(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: AppColors.onSurface,
    height: 1.1,
    letterSpacing: -0.5,
  );

  // H1 - Page titles (32-36px)
  static TextStyle h1 = GoogleFonts.bricolageGrotesque(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.2,
    letterSpacing: -0.3,
  );

  // H2 - Section titles (24-28px)
  static TextStyle h2 = GoogleFonts.bricolageGrotesque(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.3,
    letterSpacing: -0.2,
  );

  // H3 - Card titles (18-20px)
  static TextStyle h3 = GoogleFonts.bricolageGrotesque(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.4,
    letterSpacing: -0.1,
  );

  // H4 - Small headings (16px)
  static TextStyle h4 = GoogleFonts.bricolageGrotesque(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.4,
  );

  // Body Large (16-18px)
  static TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.5,
  );

  // Body Medium (14-15px) - Default body text
  static TextStyle bodyMedium = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.5,
  );

  // Body Small (12-13px)
  static TextStyle bodySmall = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceMuted,
    height: 1.4,
  );

  // Caption (10-11px) - Metadata, timestamps
  static TextStyle caption = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceLight,
    height: 1.3,
    letterSpacing: 0.3,
  );

  // Label Large - Button text (14px)
  static TextStyle labelLarge = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.2,
    letterSpacing: 0.1,
  );

  // Label Medium - Small buttons (12px)
  static TextStyle labelMedium = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.2,
    letterSpacing: 0.2,
  );

  // Label Small - Chips, tags (10px)
  static TextStyle labelSmall = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.2,
    letterSpacing: 0.5,
  );
}

// THEME DATA
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
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
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.h1,
        headlineMedium: AppTypography.h2,
        headlineSmall: AppTypography.h3,
        titleLarge: AppTypography.h4,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),
    );
  }

  // Dark theme - İsteğe bağlı
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        error: AppColors.error,
        onError: AppColors.onError,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.onSurfaceDark,
        outline: AppColors.outlineDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(color: AppColors.onSurfaceDark),
        headlineLarge: AppTypography.h1.copyWith(color: AppColors.onSurfaceDark),
        headlineMedium: AppTypography.h2.copyWith(color: AppColors.onSurfaceDark),
        headlineSmall: AppTypography.h3.copyWith(color: AppColors.onSurfaceDark),
        titleLarge: AppTypography.h4.copyWith(color: AppColors.onSurfaceDark),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.onSurfaceVariantDark),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariantDark),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariantDark),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.onSurfaceDark),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.onSurfaceVariantDark),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariantDark),
      ),
    );
  }
}
