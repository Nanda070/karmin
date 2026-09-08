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
    this.accentBarColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final KarminCardVariant variant;
  final double radius;
  final VoidCallback? onTap;
  final bool? accentBar;
  final Color? accentBarColor;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    final barColor = accentBarColor ?? palette.steel;
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
                          barColor,
                          barColor.withValues(alpha: 0.35),
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
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [palette.surfaceHi, palette.surface, palette.surfaceLo],
        stops: const [0.0, 0.45, 1.0],
      ),
      border: variant == KarminCardVariant.surface
          ? null
          : Border.all(
              color: palette.hairline.withValues(alpha: 0.85),
              width: 1,
            ),
      boxShadow: variant == KarminCardVariant.elevated
          ? [
              BoxShadow(
                color: palette.shadow,
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
          splashColor: palette.carmine.withValues(alpha: 0.08),
          highlightColor: palette.field.withValues(alpha: 0.4),
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
