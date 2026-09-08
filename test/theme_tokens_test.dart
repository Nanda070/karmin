import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:karmin/app/theme.dart';

void main() {
  test('dark tokens match the locked Figma contract', () {
    const dark = KarminPalette.dark;
    expect(dark.page, KarminColors.ink);
    expect(dark.surface, KarminColors.surface);
    expect(dark.field, KarminColors.navy);
    expect(dark.text, KarminColors.text);
    expect(dark.carmine, KarminColors.carmine);
    expect(dark.carmineBright, KarminColors.carmineBright);
    expect(dark.isDark, isTrue);
  });

  test('light tokens are cream paper, not generic white', () {
    const light = KarminPalette.light;
    expect(light.page, KarminLightColors.paper);
    expect(light.surface, KarminLightColors.surface);
    expect(light.field, KarminLightColors.field);
    expect(light.text, KarminLightColors.ink);
    expect(light.hairline, KarminLightColors.hairline);
    expect(light.muted, KarminLightColors.muted);
    expect(light.carmine, KarminColors.carmine);
    expect(light.page, isNot(const Color(0xFFFFFFFF)));
    expect(light.surface, isNot(const Color(0xFFFFFFFF)));
    expect(light.isDark, isFalse);
  });

  testWidgets('ThemeData exposes palette for both brightnesses', (tester) async {
    expect(
      KarminTheme.dark().extension<KarminPalette>()!.page,
      KarminColors.ink,
    );
    expect(
      KarminTheme.light().extension<KarminPalette>()!.page,
      KarminLightColors.paper,
    );
    expect(KarminTheme.light().scaffoldBackgroundColor, KarminLightColors.paper);
    expect(KarminTheme.dark().scaffoldBackgroundColor, KarminColors.ink);

    late KarminPalette lightPalette;
    await tester.pumpWidget(
      Theme(
        data: KarminTheme.light(),
        child: Builder(
          builder: (context) {
            lightPalette = KarminPalette.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(lightPalette.page, KarminLightColors.paper);
    expect(
      ThemeData.estimateBrightnessForColor(lightPalette.page),
      Brightness.light,
    );
  });
}
