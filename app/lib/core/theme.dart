import 'package:flutter/material.dart';

/// Erişilebilirlik öncelikli tema: yüksek kontrast, büyük dokunma hedefleri,
/// büyük yazı. Yaşlı ve görme zorluğu olan kullanıcılar için.
class ErisimTheme {
  static const seed = Color(0xFF0B6E4F); // sakin yeşil

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontSize: 20),
        labelLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(64), // büyük dokunma hedefi
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
