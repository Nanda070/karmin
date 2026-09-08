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
    this.size = 40,
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
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        splashColor: KarminColors.carmine.withValues(alpha: 0.12),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A2438), KarminColors.navy],
            ),
            border: Border.all(
              color: bordered
                  ? KarminColors.hairline
                  : KarminColors.hairline.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: child ??
                Icon(
                  icon,
                  size: size * 0.45,
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
    this.icon,
  });

  final String label;
  final String value;
  final Color valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(KarminSpacing.md),
        decoration: BoxDecoration(
          borderRadius: KarminRadii.mdBorder,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF141A26), KarminColors.surface],
          ),
          border: Border.all(color: KarminColors.hairline.withValues(alpha: 0.85)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 12, color: KarminColors.muted),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: KarminTypography.label(fontSize: 11),
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
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
