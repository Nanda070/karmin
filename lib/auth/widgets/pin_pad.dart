import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';

class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, this.max = 6});

  final int length;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < max; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < length
                  ? KarminColors.carmineBright
                  : Colors.transparent,
              border: Border.all(
                color: i < length
                    ? KarminColors.carmineBright
                    : KarminColors.hairline,
              ),
            ),
          ),
        ],
      ],
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
    if (label.isEmpty) {
      return const SizedBox(width: 72, height: 56);
    }

    final isDelete = label == '⌫';
    return Material(
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
            color: KarminColors.surface,
            borderRadius: KarminRadii.lgBorder,
            border: Border.all(color: KarminColors.hairline),
          ),
          child: Center(
            child: isDelete
                ? const Icon(
                    KarminIcons.backspace,
                    size: 20,
                    color: KarminColors.text,
                  )
                : Text(
                    label,
                    style: KarminTypography.title(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
