import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';

class KarminMark extends StatelessWidget {
  const KarminMark({super.key, this.size = 56, this.letterSize = 22});

  final double size;
  final double letterSize;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    return Semantics(
      image: true,
      label: 'Karmin',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.carmineBright, palette.carmine],
          ),
        ),
        child: Text(
          'K',
          style: KarminTypography.display(
            fontSize: letterSize,
            fontWeight: FontWeight.w600,
            color: palette.onCarmine,
          ),
        ),
      ),
    );
  }
}

class AuthBadge extends StatelessWidget {
  const AuthBadge({super.key, required this.icon, this.size = 64});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.field,
        border: Border.all(color: palette.hairline),
      ),
      child: Icon(icon, size: 24, color: palette.accentText),
    );
  }
}
