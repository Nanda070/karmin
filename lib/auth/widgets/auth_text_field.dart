import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:karmin/app/theme.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.inputFormatters,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      style: KarminTypography.body(fontSize: 14),
      cursorColor: KarminColors.carmineBright,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: KarminColors.muted),
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: KarminColors.muted,
                ),
              ),
        filled: true,
        fillColor: KarminColors.navy,
        hintStyle: KarminTypography.body(
          fontSize: 14,
          color: KarminColors.muted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: KarminRadii.mdBorder,
          borderSide: const BorderSide(color: KarminColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: KarminRadii.mdBorder,
          borderSide: const BorderSide(color: KarminColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: KarminRadii.mdBorder,
          borderSide: const BorderSide(color: KarminColors.carmine),
        ),
      ),
    );
  }
}
