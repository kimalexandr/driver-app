import 'package:flutter/material.dart';

/// Холодная логистическая палитра: slate + teal, без «песочного» фона.
class AppColors {
  static const navy = Color(0xFF0F172A);
  static const ink = Color(0xFF1E293B);
  static const sand = Color(0xFFF4F7FB);
  static const card = Color(0xFFFFFFFF);
  static const orange = Color(0xFF0D9488);
  static const amber = Color(0xFFF59E0B);
  static const green = Color(0xFF059669);
  static const red = Color(0xFFE11D48);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const softTeal = Color(0xFFCCFBF1);
  static const softSky = Color(0xFFE0F2FE);

  static const nightBg = Color(0xFF020617);
  static const nightCard = Color(0xFF0F172A);
  static const nightLine = Color(0xFF1E293B);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.orange,
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
      buttonBg: AppColors.navy,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      primary: const Color(0xFF5EEAD4),
      secondary: AppColors.amber,
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
      inputFill: const Color(0xFF111827),
      buttonBg: const Color(0xFF0F766E),
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
    required Color buttonBg,
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
        titleTextStyle: TextStyle(
          color: appBarFg,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          borderSide: const BorderSide(color: AppColors.orange, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBg,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: AppColors.line, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.softTeal,
        labelStyle: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class StatusColors {
  static Color background(String status) {
    switch (status) {
      case 'in_transit':
        return AppColors.softTeal;
      case 'delivered':
        return const Color(0xFFE2E8F0);
      case 'assigned':
        return AppColors.softSky;
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  static Color foreground(String status) {
    switch (status) {
      case 'in_transit':
        return const Color(0xFF0F766E);
      case 'delivered':
        return AppColors.navy;
      case 'assigned':
        return const Color(0xFF0369A1);
      default:
        return AppColors.muted;
    }
  }
}
