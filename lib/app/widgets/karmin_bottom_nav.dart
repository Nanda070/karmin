import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: KarminColors.ink,
        border: Border(
          top: BorderSide(color: KarminColors.hairline, width: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: KarminSpacing.pageX,
          right: KarminSpacing.pageX,
          top: 10,
          bottom: bottom > 0 ? bottom : 18,
        ),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: _NavItem(
                    label: labels[i],
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
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 16,
              height: 2,
              decoration: BoxDecoration(
                color: selected ? KarminColors.carmine : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              style: KarminTypography.tab(selected: selected),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
