import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/api/neptun_auth.dart';
import 'package:karmin/api/neptun_client.dart';
import 'package:karmin/auth/auth_controller.dart';
import 'package:karmin/auth/local_auth_probe.dart';
import 'package:karmin/auth/otp_page.dart';
import 'package:karmin/auth/prefs.dart';
import 'package:karmin/auth/providers.dart';
import 'package:karmin/auth/secure_store.dart';
import 'package:karmin/l10n/app_localizations.dart';

void main() {
  testWidgets('Verification shows Send code again for unknown channel',
      (tester) async {
    final controller = AuthController(
      store: MemorySecureStore(),
      prefs: MemoryPrefsStore(),
      authApi: DebugNeptunAuth(),
      client: NeptunClient(),
      localAuth: LocalAuthProbe(),
      usingDebugAuth: true,
      hydrateOnStart: false,
    );
    await controller.acceptDisclaimer();
    await controller.login(userName: 'abc123', password: 'secret', lcid: 1033);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OtpPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Send code again'), findsOneWidget);
    expect(
      find.text(
        'This build uses the email code only; authenticator is temporarily off.',
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Send code again'));
    await tester.pump();

    expect(find.text('123456'), findsNothing);
    expect(find.text('A new code was requested.'), findsOneWidget);
    expect(find.textContaining('Send again in'), findsOneWidget);
  });
}
