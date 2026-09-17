import 'package:flutter/material.dart';

/// Высокий контраст для водителя: тёмный текст на светлом фоне.
class AppColors {
  static const navy = Color(0xFF0B1220);
  static const ink = Color(0xFF1A2332);
  static const sand = Color(0xFFF7F9FC);
  static const card = Color(0xFFFFFFFF);
  static const orange = Color(0xFF0F766E);
  static const amber = Color(0xFFD97706);
  static const green = Color(0xFF047857);
  static const red = Color(0xFFDC2626);
  static const muted = Color(0xFF475569);
  static const line = Color(0xFFCBD5E1);
  static const softTeal = Color(0xFFCCFBF1);
  static const softSky = Color(0xFFE0F2FE);

  static const nightBg = Color(0xFF020617);
  static const nightCard = Color(0xFF111827);
  static const nightLine = Color(0xFF334155);
  static const nightText = Color(0xFFF8FAFC);
  static const nightMuted = Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.navy,
      onPrimary: Colors.white,
      secondary: AppColors.orange,
      onSecondary: Colors.white,
      error: AppColors.red,
      onError: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.navy,
      surfaceContainerHighest: AppColors.sand,
      outline: AppColors.line,
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
      bodyColor: AppColors.navy,
      mutedColor: AppColors.muted,
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF2DD4BF),
      onPrimary: AppColors.navy,
      secondary: AppColors.amber,
      onSecondary: AppColors.navy,
      error: Color(0xFFF87171),
      onError: AppColors.navy,
      surface: AppColors.nightCard,
      onSurface: AppColors.nightText,
      surfaceContainerHighest: Color(0xFF1E293B),
      outline: AppColors.nightLine,
    );
    return _base(
      scheme: scheme,
      scaffold: AppColors.nightBg,
      card: AppColors.nightCard,
      line: AppColors.nightLine,
      appBarBg: AppColors.nightCard,
      appBarFg: AppColors.nightText,
      inputFill: const Color(0xFF1E293B),
      buttonBg: const Color(0xFF0F766E),
      bodyColor: AppColors.nightText,
      mutedColor: AppColors.nightMuted,
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
    required Color bodyColor,
    required Color mutedColor,
  }) {
    final textTheme = TextTheme(
      bodyLarge: TextStyle(color: bodyColor, fontSize: 16, height: 1.35),
      bodyMedium: TextStyle(color: bodyColor, fontSize: 14, height: 1.35),
      bodySmall: TextStyle(color: mutedColor, fontSize: 13, height: 1.3),
      titleLarge: TextStyle(
        color: bodyColor,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: bodyColor,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      labelLarge: TextStyle(
        color: bodyColor,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      cardColor: card,
      dividerColor: line,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
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
        labelStyle: TextStyle(color: mutedColor, fontWeight: FontWeight.w600),
        floatingLabelStyle: TextStyle(
          color: scheme.secondary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(color: mutedColor.withValues(alpha: 0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: line, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.secondary, width: 2),
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
          foregroundColor: bodyColor,
          minimumSize: const Size(double.infinity, 54),
          side: BorderSide(color: line, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.softTeal,
        labelStyle: TextStyle(color: bodyColor, fontWeight: FontWeight.w700),
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
