import 'dart:ui';

import 'package:flutter/material.dart';

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final int? maxLines;
  final String? Function(String?)? validator;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffixIcon,
    this.maxLines,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final field = validator != null
        ? TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            maxLines: obscure ? 1 : maxLines,
            validator: validator,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: suffixIcon,
              errorStyle: TextStyle(
                color: Colors.red[300],
                fontSize: 12,
              ),
            ),
          )
        : TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            maxLines: obscure ? 1 : maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: suffixIcon,
            ),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: field,
      ),
    );
  }
}



