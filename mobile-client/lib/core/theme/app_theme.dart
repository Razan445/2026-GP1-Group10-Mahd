import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ──────────────────────────────────────────────
//  Mahd Design System — Color Palette
// ──────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color backgroundCream = Color(0xFFFBF5EF);
  static const Color backgroundBeige = Color(0xFFF4EBE2);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color gradientStart = Color(0xFFFDEDE2);
  static const Color gradientEnd = Color(0xFFF8DBC8);

  // Primary (Peach / Orange)
  static const Color primaryLight = Color(0xFFE9A97F);
  static const Color primary = Color(0xFFCE7E52);
  static const Color primaryDark = Color(0xFFB0663C);
  static const Color primaryButtonStart = Color(0xFFEDAF85);
  static const Color primaryButtonEnd = Color(0xFFDD9163);

  // Dark / Text
  static const Color textPrimary = Color(0xFF3A2B23);
  static const Color textSecondary = Color(0xFF7C6355);
  static const Color textHelper = Color(0xFF6B5446);
  static const Color textLabel = Color(0xFF6B564A);

  // Borders
  static const Color borderBeige = Color(0xFFEFDDD0);
  static const Color borderLight = Color(0xFFF1E4D9);
  static const Color borderMedium = Color(0xFFF2E6DB);

  // Semantic — Success (Green)
  static const Color success = Color(0xFF7E9B7A);
  static const Color successBg = Color(0xFFEDF2EB);

  // Semantic — Alert / Error (Red)
  static const Color alert = Color(0xFFBE5A43);
  static const Color alertBg = Color(0xFFFDF1EC);
  static const Color alertBorder = Color(0xFFF1CFC6);

  // Semantic — Unclassified
  static const Color unclassified = Color(0xFFF4EDE6);

  // Icon backgrounds
  static const Color iconBg = Color(0xFFFDEADF);

  // Secondary button / Dark surface
  static const Color darkSurface = Color(0xFF3A2B23);
  static const Color darkSurfaceText = Color(0xFFFDF3EA);
}

// ──────────────────────────────────────────────
//  Mahd Design System — Typography
//  Uses Google Fonts: IBM Plex Sans Arabic
// ──────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.ibmPlexSansArabic(
        color: AppColors.textPrimary,
      );

  /// عنوان رئيسي – SemiBold 26–28
  static TextStyle get displayTitle => _base.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 26,
        height: 1.5,
      );

  /// عنوان شاشة – SemiBold 24
  static TextStyle get screenTitle => _base.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 24,
        height: 1.5,
      );

  /// عنوان بطاقة – Medium 14
  static TextStyle get cardTitle => _base.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 1.5,
      );

  /// نص أساسي – Regular 14 / 1.8
  static TextStyle get bodyText => _base.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.8,
      );

  /// نص مساعد – Light 12.5
  static TextStyle get helperText => _base.copyWith(
        fontWeight: FontWeight.w300,
        fontSize: 12.5,
        height: 1.7,
        color: AppColors.textSecondary,
      );

  /// تسميات حقول – Medium 12.5
  static TextStyle get fieldLabel => _base.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 12.5,
        height: 2.0,
        color: AppColors.textLabel,
      );

  /// زر أساسي – SemiBold 15
  static TextStyle get buttonText => _base.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: Colors.white,
      );

  /// زر ثانوي – Medium 15
  static TextStyle get buttonTextDark => _base.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 15,
        color: AppColors.textPrimary,
      );

  /// Splash tagline – SemiBold 17
  static TextStyle get splashTagline => _base.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 17,
        height: 1.6,
      );

  /// Splash sub – Light 13
  static TextStyle get splashSub => _base.copyWith(
        fontWeight: FontWeight.w300,
        fontSize: 13,
        height: 1.7,
        color: AppColors.textSecondary,
      );

  /// Welcome title – SemiBold 22
  static TextStyle get welcomeTitle => _base.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 22,
        height: 1.5,
      );

  /// Feature card description – Light 12
  static TextStyle get featureDesc => _base.copyWith(
        fontWeight: FontWeight.w300,
        fontSize: 12,
        height: 1.6,
        color: AppColors.textSecondary,
      );
}

// ──────────────────────────────────────────────
//  Mahd ThemeData
// ──────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final baseTextTheme = GoogleFonts.ibmPlexSansArabicTextTheme();

    return ThemeData(
      useMaterial3: true,
      textTheme: baseTextTheme,
      scaffoldBackgroundColor: AppColors.backgroundCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.backgroundCream,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        onSecondary: Colors.white,
        error: AppColors.alert,
        onError: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.screenTitle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSurface,
        hintStyle: GoogleFonts.ibmPlexSansArabic(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.borderLight, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.borderLight, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFFDE9B88), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.alert, width: 1.5),
        ),
        errorStyle: GoogleFonts.ibmPlexSansArabic(
          color: AppColors.alert,
          fontSize: 11.5,
          height: 1.9,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13.5),
      ),
    );
  }
}
