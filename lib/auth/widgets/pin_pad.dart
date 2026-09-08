import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';
import 'package:karmin/l10n/app_localizations.dart';

class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, this.max = 6});

  final int length;
  final int max;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      label: l10n.pinDotsLabel(length, max),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < max; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < length ? palette.accentText : Colors.transparent,
                border: Border.all(
                  color: i < length ? palette.accentText : palette.hairline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: [
        for (final row in keys) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < row.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                _Key(
                  label: row[i],
                  enabled: enabled,
                  onDigit: onDigit,
                  onBackspace: onBackspace,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
  });

  final String label;
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    final l10n = AppLocalizations.of(context);
    if (label.isEmpty) {
      return const SizedBox(width: 72, height: 56);
    }

    final isDelete = label == '⌫';
    final semanticsLabel =
        isDelete ? l10n.pinBackspace : l10n.pinDigit(label);
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: !enabled
              ? null
              : () {
                  if (isDelete) {
                    onBackspace();
                  } else {
                    onDigit(label);
                  }
                },
          borderRadius: KarminRadii.lgBorder,
          child: Ink(
            width: 72,
            height: 56,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: KarminRadii.lgBorder,
              border: Border.all(color: palette.hairline),
            ),
            child: Center(
              child: isDelete
                  ? Icon(
                      KarminIcons.backspace,
                      size: 20,
                      color: palette.text,
                    )
                  : Text(
                      label,
                      style: KarminTypography.title(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
