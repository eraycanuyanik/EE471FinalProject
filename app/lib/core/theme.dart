import 'package:flutter/material.dart';

/// Erişim tasarım sistemi — modern, yüksek kontrastlı, erişilebilir.
class ErisimTheme {
  // Marka renkleri
  static const primary = Color(0xFF1565C0);   // canlı mavi
  static const bgTop = Color(0xFF0D1B2A);     // koyu lacivert (header gradyan)
  static const bgBottom = Color(0xFF1B3A5B);

  // Modül renkleri (her modülün kimliği)
  static const sesverA = Color(0xFF5E35B1);
  static const sesverB = Color(0xFF7E57C2);
  static const duyarA = Color(0xFF00897B);
  static const duyarB = Color(0xFF26A69A);
  static const yaninA = Color(0xFFE64A19);
  static const yaninB = Color(0xFFFF7043);

  static const danger = Color(0xFFD32F2F);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 18),
        labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(60),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  /// Koyu degrade header arka planı.
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgTop, bgBottom],
  );
}
