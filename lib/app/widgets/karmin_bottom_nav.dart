import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';

class KarminBottomNav extends StatelessWidget {
  const KarminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.labels,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<String> labels;

  static const _icons = [
    KarminIcons.home,
    KarminIcons.calendar,
    KarminIcons.study,
    KarminIcons.inbox,
  ];

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.page.withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(color: palette.hairline, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: KarminSpacing.lg,
          right: KarminSpacing.lg,
          top: 10,
          bottom: bottom > 0 ? bottom : 14,
        ),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: _NavItem(
                    label: labels[i],
                    icon: _icons[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    final color = selected ? palette.accentText : palette.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: selected ? 48 : 36,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          palette.carmine.withValues(alpha: 0.28),
                          palette.carmine.withValues(alpha: 0.08),
                        ],
                      )
                    : null,
                border: selected
                    ? Border.all(
                        color: palette.carmine.withValues(alpha: 0.35),
                      )
                    : null,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              style: KarminTypography.label(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
