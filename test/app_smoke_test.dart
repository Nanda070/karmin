import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karmin/api/neptun_auth.dart';
import 'package:karmin/api/neptun_client.dart';
import 'package:karmin/app/app.dart';
import 'package:karmin/auth/auth_controller.dart';
import 'package:karmin/auth/auth_models.dart';
import 'package:karmin/auth/local_auth_probe.dart';
import 'package:karmin/auth/prefs.dart';
import 'package:karmin/auth/providers.dart';
import 'package:karmin/auth/secure_store.dart';
import 'package:karmin/data/cache_store.dart';
import 'package:karmin/data/providers.dart';
import 'package:karmin/l10n/app_localizations.dart';

void main() {
  testWidgets('Today chrome and Settings gear after unlock', (tester) async {
    final prefs = MemoryPrefsStore()..disclaimerAccepted = true;
    final store = MemorySecureStore();
    final client = NeptunClient()..setAccessToken('debug-jwt');
    final controller = AuthController(
      store: store,
      prefs: prefs,
      authApi: DebugNeptunAuth(),
      client: client,
      localAuth: LocalAuthProbe(),
      usingDebugAuth: true,
      hydrateOnStart: false,
    )..debugSetState(AuthState.unlockedSession());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsStoreProvider.overrideWithValue(prefs),
          secureStoreProvider.overrideWithValue(store),
          neptunClientProvider.overrideWithValue(client),
          debugAuthFlagProvider.overrideWithValue(true),
          cacheStoreProvider.overrideWithValue(MemoryCacheStore()),
          authControllerProvider.overrideWith((ref) => controller),
        ],
        child: const KarminApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Next class'), findsOneWidget);
    expect(find.text('Analysis II'), findsWidgets);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Adnan Huseynli'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
  });

  test('l10n English template loads', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      containsAll(['en', 'hu', 'ru']),
    );
  });
}
