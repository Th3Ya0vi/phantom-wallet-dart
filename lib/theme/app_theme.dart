import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: Brightness.light,
        surface: AppColors.bgSurface,
        onSurface: AppColors.textDefault,
        primary: AppColors.brand,
        onPrimary: Colors.white,
        secondary: AppColors.blue,
        tertiary: AppColors.lavender,
      ),
      scaffoldBackgroundColor: AppColors.bgPage,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgSurface,
        foregroundColor: AppColors.textDefault,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textDefault,
          fontSize: 20,
          fontWeight: FontWeight.w600,

        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
  
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDefault,
          side: BorderSide(color: AppColors.gray200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
  
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textDefault,
          fontSize: 32,
          fontWeight: FontWeight.bold,

        ),
        headlineMedium: TextStyle(
          color: AppColors.textDefault,
          fontSize: 24,
          fontWeight: FontWeight.w600,

        ),
        titleLarge: TextStyle(
          color: AppColors.textDefault,
          fontSize: 20,
          fontWeight: FontWeight.w600,

        ),
        titleMedium: TextStyle(
          color: AppColors.textDefault,
          fontSize: 16,
          fontWeight: FontWeight.w500,

        ),
        bodyLarge: TextStyle(
          color: AppColors.textDefault,
          fontSize: 16,
          fontWeight: FontWeight.normal,

        ),
        bodyMedium: TextStyle(
          color: AppColors.textDefault,
          fontSize: 14,
          fontWeight: FontWeight.normal,

        ),
        bodySmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.normal,

        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.orange),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
