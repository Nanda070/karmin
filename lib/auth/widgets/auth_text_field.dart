import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/l10n/app_localizations.dart';

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
    this.semanticsLabel,
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
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      textField: true,
      label: semanticsLabel ?? hint,
      obscured: obscure,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        autofillHints: autofillHints,
        inputFormatters: inputFormatters,
        style: KarminTypography.body(fontSize: 14, color: palette.text),
        cursorColor: palette.accentText,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: palette.muted),
          suffixIcon: onToggleObscure == null
              ? null
              : IconButton(
                  onPressed: onToggleObscure,
                  tooltip: obscure
                      ? l10n.loginShowPassword
                      : l10n.loginHidePassword,
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: palette.muted,
                  ),
                ),
          filled: true,
          fillColor: palette.field,
          hintStyle: KarminTypography.body(
            fontSize: 14,
            color: palette.muted,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: KarminRadii.mdBorder,
            borderSide: BorderSide(color: palette.hairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: KarminRadii.mdBorder,
            borderSide: BorderSide(color: palette.hairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: KarminRadii.mdBorder,
            borderSide: BorderSide(color: palette.carmine),
          ),
        ),
      ),
    );
  }
}
