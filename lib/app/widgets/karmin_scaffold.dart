import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:karmin/app/theme.dart';

/// AppBar-less page chrome with ink→navy / paper→field atmosphere.
class KarminScaffold extends StatelessWidget {
  const KarminScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    final overlay = palette.isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: palette.page,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: palette.page,
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: palette.page,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.page, palette.pageMid, palette.pageEnd],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: bottomNavigationBar == null,
            child: body,
          ),
        ),
      ),
    );
  }
}

/// Large iOS-style title row with optional trailing actions.
class KarminPageHeader extends StatelessWidget {
  const KarminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.titleStyle,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KarminSpacing.pageX,
        KarminSpacing.md,
        KarminSpacing.pageX,
        KarminSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: KarminSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: titleStyle ??
                      KarminTypography.display(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: KarminTypography.body(
                      fontSize: 13,
                      color: palette.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class KarminCircleButton extends StatelessWidget {
  const KarminCircleButton({
    super.key,
    required this.onPressed,
    this.child,
    this.icon,
    this.tooltip,
    this.size = 48,
    this.bordered = false,
  });

  final VoidCallback onPressed;
  final Widget? child;
  final IconData? icon;
  final String? tooltip;
  final double size;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    final visual = size < KarminSpacing.tap ? KarminSpacing.tap : size;
    final button = Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          splashColor: palette.carmine.withValues(alpha: 0.12),
          child: Ink(
            width: visual,
            height: visual,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.fieldHi, palette.field],
              ),
              border: Border.all(
                color: bordered
                    ? palette.hairline
                    : palette.hairline.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: child ??
                  Icon(
                    icon,
                    size: visual * 0.42,
                    color: palette.text,
                  ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class KarminStatChip extends StatelessWidget {
  const KarminStatChip({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(KarminSpacing.md),
        decoration: BoxDecoration(
          borderRadius: KarminRadii.mdBorder,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.surfaceHi, palette.surface],
          ),
          border: Border.all(color: palette.hairline.withValues(alpha: 0.85)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 12, color: palette.muted),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: KarminTypography.label(
                      fontSize: 11,
                      color: palette.muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: KarminTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? palette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
