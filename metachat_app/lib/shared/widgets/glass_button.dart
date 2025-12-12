import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/liquid_glass_theme.dart';

class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.black : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: GestureDetector(
        onTap: onPressed,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 20,
            sigmaY: 20,
          ),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: filled ? LiquidGlassGradients.accentGlow : null,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.36),
              ),
              color: filled ? null : Colors.white.withOpacity(0.06),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: child,
          ),
        ),
      ),
    );
  }
}



