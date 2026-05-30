import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static TextTheme _textTheme(Color primary, Color secondary) {
    return GoogleFonts.plusJakartaSansTextTheme().copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 56, fontWeight: FontWeight.w800, color: primary, height: 1.1,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 44, fontWeight: FontWeight.w800, color: primary, height: 1.15,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 36, fontWeight: FontWeight.w700, color: primary, height: 1.2,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 30, fontWeight: FontWeight.w700, color: primary, height: 1.25,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24, fontWeight: FontWeight.w700, color: primary, height: 1.3,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 20, fontWeight: FontWeight.w600, color: primary, height: 1.35,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18, fontWeight: FontWeight.w600, color: primary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w600, color: primary,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w600, color: primary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w400, color: secondary, height: 1.55,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w400, color: secondary, height: 1.55,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12, fontWeight: FontWeight.w400, color: secondary, height: 1.5,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w600, color: primary,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12, fontWeight: FontWeight.w600, color: primary,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11, fontWeight: FontWeight.w600, color: secondary,
        letterSpacing: 0.5,
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brand,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightText,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.lightBorder,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: _textTheme(AppColors.lightText, AppColors.lightTextMuted),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.lightText,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.lightTextMuted,
          fontSize: 14,
        ),
        errorStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.error,
          fontSize: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.lightBorder,
          disabledForegroundColor: AppColors.lightTextMuted,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightText,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandLight,
        onPrimary: Colors.white,
        secondary: AppColors.accentLight,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.darkBorder,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: _textTheme(AppColors.darkText, AppColors.darkTextMuted),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextMuted,
          fontSize: 14,
        ),
        errorStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.error,
          fontSize: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandLight,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.darkBorder,
          disabledForegroundColor: AppColors.darkTextMuted,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkText,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandLight,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
