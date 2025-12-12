import 'package:flutter/material.dart';

ThemeData buildMetachatTheme() {
  const background = Color(0xFF0A0A0F);
  const primary = Color(0xFF7DD3FC);
  const secondary = Color(0xFFC4B5FD);

  final colorScheme = const ColorScheme.dark().copyWith(
    primary: primary,
    secondary: secondary,
    background: background,
    surface: Colors.white.withOpacity(0.05),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: primary,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
    ),
  );
}



