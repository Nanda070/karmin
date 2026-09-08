import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';

class KarminSectionLabel extends StatelessWidget {
  const KarminSectionLabel(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.only(bottom: KarminSpacing.sm),
  });

  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: KarminTypography.label(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: palette.muted,
        ),
      ),
    );
  }
}
