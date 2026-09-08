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
    final palette = KarminPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: KarminRadii.smBorder,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? palette.field : palette.surface,
                borderRadius: KarminRadii.smBorder,
                border: Border.all(
                  color: selected ? palette.steel : palette.hairline,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: KarminTypography.label(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? palette.text : palette.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
