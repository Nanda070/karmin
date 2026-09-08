import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';

class KarminPrimaryButton extends StatelessWidget {
  const KarminPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: KarminRadii.mdBorder,
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            borderRadius: KarminRadii.mdBorder,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                KarminColors.carmineBright,
                KarminColors.carmine,
                Color(0xFF6E1222),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: KarminColors.carmine.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: KarminColors.carmineBright.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: KarminColors.text,
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(icon, size: 18, color: KarminColors.text),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: KarminTypography.body(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
