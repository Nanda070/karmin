import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';

class KarminFilterChip extends StatelessWidget {
  const KarminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: KarminRadii.smBorder,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? KarminColors.navy
                : KarminColors.surface,
            borderRadius: KarminRadii.smBorder,
            border: Border.all(
              color: selected ? KarminColors.steel : KarminColors.hairline,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: KarminTypography.label(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? KarminColors.text : KarminColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
