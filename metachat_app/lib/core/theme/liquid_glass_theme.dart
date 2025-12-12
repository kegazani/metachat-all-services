import 'package:flutter/material.dart';

class LiquidGlassColors {
  static const background = Color(0xFF0A0A0F);
  static const primary = Color(0xFF7DD3FC);
  static const secondary = Color(0xFFC4B5FD);
  static const surfaceTint = Colors.white;
}

class LiquidGlassGradients {
  static const LinearGradient primaryGlass = LinearGradient(
    colors: [
      Color(0x40FFFFFF),
      Color(0x10FFFFFF),
      Color(0x4080D0FF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGlow = LinearGradient(
    colors: [
      Color(0x807DD3FC),
      Color(0x40C4B5FD),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}



