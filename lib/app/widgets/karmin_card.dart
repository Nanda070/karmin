import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';

enum KarminCardVariant { surface, outlined }

class KarminCard extends StatelessWidget {
  const KarminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(KarminSpacing.lg),
    this.margin,
    this.variant = KarminCardVariant.outlined,
    this.radius = KarminRadii.lg,
    this.onTap,
    this.accentBar,
    this.accentBarColor = KarminColors.steel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final KarminCardVariant variant;
  final double radius;
  final VoidCallback? onTap;
  final bool? accentBar;
  final Color accentBarColor;

  @override
  Widget build(BuildContext context) {
    final showBar = accentBar == true;
    final borderRadius = BorderRadius.circular(radius);

    Widget content = Padding(
      padding: padding,
      child: showBar
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 3,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentBarColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: KarminSpacing.md),
                  Expanded(child: child),
                ],
              ),
            )
          : child,
    );

    final decoration = BoxDecoration(
      color: KarminColors.surface,
      borderRadius: borderRadius,
      border: variant == KarminCardVariant.outlined
          ? Border.all(color: KarminColors.hairline, width: 1)
          : null,
    );

    Widget card = DecoratedBox(
      decoration: decoration,
      child: content,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: KarminColors.carmine.withValues(alpha: 0.08),
          highlightColor: KarminColors.navy.withValues(alpha: 0.4),
          child: card,
        ),
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}
