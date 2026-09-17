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

  static const nightBg = Color(0xFF0E1620);
  static const nightCard = Color(0xFF1A2430);
  static const nightLine = Color(0xFF2A3644);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      secondary: AppColors.orange,
      surface: AppColors.sand,
      error: AppColors.red,
      brightness: Brightness.light,
    );
    return _base(
      scheme: scheme,
      scaffold: AppColors.sand,
      card: AppColors.card,
      line: AppColors.line,
      appBarBg: AppColors.navy,
      appBarFg: Colors.white,
      inputFill: Colors.white,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: const Color(0xFF7EB6E8),
      secondary: AppColors.orange,
      surface: AppColors.nightCard,
      error: AppColors.red,
      brightness: Brightness.dark,
    );
    return _base(
      scheme: scheme,
      scaffold: AppColors.nightBg,
      card: AppColors.nightCard,
      line: AppColors.nightLine,
      appBarBg: AppColors.nightCard,
      appBarFg: Colors.white,
      inputFill: AppColors.nightCard,
    );
  }

  static ThemeData _base({
    required ColorScheme scheme,
    required Color scaffold,
    required Color card,
    required Color line,
    required Color appBarBg,
    required Color appBarFg,
    required Color inputFill,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      cardColor: card,
      dividerColor: line,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
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
          foregroundColor: scheme.primary,
          minimumSize: const Size(double.infinity, 54),
          side: BorderSide(color: scheme.primary),
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
        return const Color(0xFFE8E2D6);
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
        return AppColors.navy;
      case 'assigned':
        return AppColors.ink;
      default:
        return AppColors.muted;
    }
  }
}
