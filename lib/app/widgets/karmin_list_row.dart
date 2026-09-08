import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_card.dart';

class KarminListRow extends StatelessWidget {
  const KarminListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.outlined = false,
    this.titleStyle,
    this.trailingStyle,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool outlined;
  final TextStyle? titleStyle;
  final TextStyle? trailingStyle;

  @override
  Widget build(BuildContext context) {
    return KarminCard(
      variant:
          outlined ? KarminCardVariant.outlined : KarminCardVariant.surface,
      radius: KarminRadii.md,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      onTap: onTap,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: KarminSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: titleStyle ??
                      KarminTypography.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: KarminTypography.body(
                      fontSize: 12,
                      color: KarminColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: KarminSpacing.md),
            DefaultTextStyle(
              style: trailingStyle ??
                  KarminTypography.body(
                    fontSize: 13,
                    color: KarminColors.muted,
                  ),
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}
