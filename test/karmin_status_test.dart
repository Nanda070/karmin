import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_status.dart';
import 'package:karmin/data/student_repository.dart';
import 'package:karmin/l10n/app_localizations.dart';

Widget _harness({
  required Widget child,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme ?? KarminTheme.dark(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('empty state shows shared copy', (tester) async {
    await tester.pumpWidget(
      _harness(child: const KarminEmptyState(message: 'Nothing on the schedule today.')),
    );
    expect(find.text('Nothing on the schedule today.'), findsOneWidget);
  });

  testWidgets('error banner offers retry', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _harness(
        child: KarminStatusBanner(
          message: "Can't refresh from Neptun.",
          onRetry: () => tapped = true,
          retryLabel: 'Try again',
        ),
      ),
    );
    expect(find.text("Can't refresh from Neptun."), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(tapped, isTrue);
  });

  testWidgets('cached snapshot uses last-saved copy', (tester) async {
    final snapshot = StudentSnapshot.empty(
      errorMessage: "Can't reach Neptun.",
    ).copyWith(fromCache: true);

    await tester.pumpWidget(
      _harness(
        child: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return KarminStatusBanner.fromSnapshot(
              snapshot: snapshot,
              l10n: l10n,
              onRetry: () {},
            );
          },
        ),
      ),
    );
    expect(find.text('Showing last saved data.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('empty and banner render on light cream theme', (tester) async {
    await tester.pumpWidget(
      _harness(
        theme: KarminTheme.light(),
        child: const Column(
          children: [
            KarminEmptyState(message: 'No messages.'),
            KarminStatusBanner(message: "Can't reach Neptun."),
          ],
        ),
      ),
    );
    expect(find.text('No messages.'), findsOneWidget);
    expect(find.text("Can't reach Neptun."), findsOneWidget);
  });
}
