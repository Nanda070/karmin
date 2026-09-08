import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';

class KarminPrimaryButton extends StatelessWidget {
  const KarminPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
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
              if (icon != null) ...[
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
    );
  }
}
