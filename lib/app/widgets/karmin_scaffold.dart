import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:karmin/app/theme.dart';

/// AppBar-less page chrome with ink→navy atmosphere and safe padding.
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: KarminColors.ink,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: KarminColors.ink,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                KarminColors.ink,
                Color(0xFF0C1018),
                KarminColors.navy,
              ],
              stops: [0.0, 0.55, 1.0],
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
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: KarminTypography.body(
                      fontSize: 13,
                      color: KarminColors.muted,
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
    this.size = 36,
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
    final button = Material(
      color: KarminColors.navy,
      shape: CircleBorder(
        side: bordered
            ? const BorderSide(color: KarminColors.hairline)
            : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        splashColor: KarminColors.carmine.withValues(alpha: 0.12),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: child ??
                Icon(
                  icon,
                  size: size * 0.5,
                  color: KarminColors.text,
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
    this.valueColor = KarminColors.text,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(KarminSpacing.md),
        decoration: BoxDecoration(
          color: KarminColors.surface,
          borderRadius: KarminRadii.mdBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: KarminTypography.label(fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: KarminTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
