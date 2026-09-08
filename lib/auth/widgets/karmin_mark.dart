import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';

class KarminMark extends StatelessWidget {
  const KarminMark({super.key, this.size = 56, this.letterSize = 22});

  final double size;
  final double letterSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KarminColors.carmineBright, KarminColors.carmine],
        ),
      ),
      child: Text(
        'K',
        style: KarminTypography.display(
          fontSize: letterSize,
          fontWeight: FontWeight.w600,
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
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KarminColors.navy,
        border: Border.all(color: KarminColors.hairline),
      ),
      child: Icon(icon, size: 24, color: KarminColors.carmineBright),
    );
  }
}
