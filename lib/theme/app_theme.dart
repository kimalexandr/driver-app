import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF12263A);
  static const ink = Color(0xFF1B3654);
  static const sand = Color(0xFFF6F1E8);
  static const card = Color(0xFFFFFFFF);
  static const orange = Color(0xFFE07A2F);
  static const green = Color(0xFF2F7D4F);
  static const red = Color(0xFFC44536);
  static const muted = Color(0xFF6B7785);
  static const line = Color(0xFFE6DED0);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      secondary: AppColors.orange,
      surface: AppColors.sand,
      error: AppColors.red,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.sand,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: AppColors.navy),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class StatusColors {
  static Color background(String status) {
    switch (status) {
      case 'in_transit':
        return const Color(0xFFFFE8D2);
      case 'delivered':
        return const Color(0xFFDCEFE3);
      case 'assigned':
        return const Color(0xFFD9E6F5);
      default:
        return const Color(0xFFEFEBE3);
    }
  }

  static Color foreground(String status) {
    switch (status) {
      case 'in_transit':
        return AppColors.orange;
      case 'delivered':
        return AppColors.green;
      case 'assigned':
        return AppColors.ink;
      default:
        return AppColors.muted;
    }
  }
}
