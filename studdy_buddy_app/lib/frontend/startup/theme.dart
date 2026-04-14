import 'package:flutter/material.dart';

class StuddyBuddyTheme {
  static const teal      = Color(0xFF79C7C5);
  static const skyBlue   = Color(0xFFADE1E5);
  static const sage      = Color(0xFF99D19C);
  static const forest    = Color(0xFF73AB84);
  static const nearBlack = Color(0xFF1A1A1A);

  // Surface palette
  static const surfaceBase      = Color(0xFFFFFFFF); // cards, sheets
  static const surfaceDim       = Color(0xFFF0F9FA); // scaffold background
  static const surfaceMid       = Color(0xFFE3F4F5); // subtle containers
  static const surfaceContainer = Color(0xFFD4EEF0); // prominent containers

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: teal,
      onPrimary: Colors.white,
      secondary: skyBlue,
      onSecondary: nearBlack,
      tertiary: forest,
      onTertiary: Colors.white,
      primaryContainer: sage,
      onPrimaryContainer: nearBlack,
      surface: surfaceBase,
      onSurface: nearBlack,
      surfaceContainerLowest: surfaceBase,
      surfaceContainerLow: surfaceDim,
      surfaceContainer: surfaceMid,
      surfaceContainerHigh: surfaceContainer,
      surfaceContainerHighest: Color(0xFFC6E8EB),
      error: Color(0xFFB3261E),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: surfaceDim,
    appBarTheme: const AppBarTheme(
      backgroundColor: teal,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: forest,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: surfaceBase,
      elevation: 2,
      shadowColor: Color(0x1A79C7C5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge:   TextStyle(color: nearBlack, fontWeight: FontWeight.w700),
      displayMedium:  TextStyle(color: nearBlack, fontWeight: FontWeight.w700),
      displaySmall:   TextStyle(color: nearBlack, fontWeight: FontWeight.w700),
      headlineLarge:  TextStyle(color: nearBlack, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: nearBlack, fontWeight: FontWeight.w600),
      headlineSmall:  TextStyle(color: nearBlack, fontWeight: FontWeight.w600),
      titleLarge:     TextStyle(color: nearBlack, fontWeight: FontWeight.w600),
      titleMedium:    TextStyle(color: nearBlack, fontWeight: FontWeight.w500),
      titleSmall:     TextStyle(color: nearBlack, fontWeight: FontWeight.w500),
      bodyLarge:      TextStyle(color: nearBlack),
      bodyMedium:     TextStyle(color: nearBlack),
      bodySmall:      TextStyle(color: Color(0xFF555555)),
      labelLarge:     TextStyle(color: nearBlack, fontWeight: FontWeight.w600),
      labelMedium:    TextStyle(color: Color(0xFF555555)),
      labelSmall:     TextStyle(color: Color(0xFF555555)),
    ),
    iconTheme: const IconThemeData(color: nearBlack),
    dividerColor: const Color(0xFFE0E0E0),
  );
}