import 'package:flutter/material.dart';

class AppTheme {
  // プライマリカラー：深い青（知識と学習を象徴）
  static const Color primaryColor = Color(0xFF1A73E8);
  
  // セカンダリカラー：暖かいオレンジ（創造性を象徴）
  static const Color secondaryColor = Color(0xFFF57C00);
  
  // アクセントカラー：洗練された緑（集中と成長を象徴）
  static const Color accentColor = Color(0xFF0F9D58);
  
  // 背景色：明るい白（クリーンな学習環境）
  static const Color backgroundColor = Color(0xFFF8F9FA);
  
  // エラー色
  static const Color errorColor = Color(0xFFD32F2F);

  // ライトテーマ
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      background: backgroundColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: Color(0xFF202124),
      ),
      headlineMedium: TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        color: Color(0xFF202124),
      ),
      titleLarge: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: Color(0xFF202124),
      ),
      bodyLarge: TextStyle(
        fontSize: 16.0,
        color: Color(0xFF202124),
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0,
        color: Color(0xFF5F6368),
      ),
    ),
  );

  // ダークテーマ
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16.0,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0,
        color: Color(0xFFBDC1C6),
      ),
    ),
  );
}