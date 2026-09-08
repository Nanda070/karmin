import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karmin/app/app.dart';
import 'package:karmin/l10n/app_localizations.dart';

void main() {
  testWidgets('Today chrome and Settings gear', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KarminApp()));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Next class'), findsOneWidget);
    expect(find.text('Analysis II'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Adnan Huseynli'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  test('l10n English template loads', () {
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode),
        containsAll(['en', 'hu', 'ru']));
  });
}
