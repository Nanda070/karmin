import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';

enum KarminCardVariant { surface, outlined, elevated }

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
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accentBarColor,
                          accentBarColor.withValues(alpha: 0.35),
                        ],
                      ),
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
      borderRadius: borderRadius,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF141A26),
          KarminColors.surface,
          Color(0xFF0C1018),
        ],
        stops: [0.0, 0.45, 1.0],
      ),
      border: variant == KarminCardVariant.surface
          ? null
          : Border.all(
              color: KarminColors.hairline.withValues(alpha: 0.85),
              width: 1,
            ),
      boxShadow: variant == KarminCardVariant.elevated
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
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
