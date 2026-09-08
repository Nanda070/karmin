import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/api/neptun_auth.dart';
import 'package:karmin/api/neptun_client.dart';
import 'package:karmin/auth/auth_controller.dart';
import 'package:karmin/auth/auth_models.dart';
import 'package:karmin/auth/local_auth_probe.dart';
import 'package:karmin/auth/otp_page.dart';
import 'package:karmin/auth/prefs.dart';
import 'package:karmin/auth/providers.dart';
import 'package:karmin/auth/secure_store.dart';
import 'package:karmin/l10n/app_localizations.dart';

class _EmailOtpAuth implements NeptunAuthApi {
  @override
  Future<AuthTicket> submitPassword({
    required String userName,
    required String password,
    required int lcid,
  }) async {
    return const AuthTicket(
      step: NeptunAuthStep.needsOtp,
      otpChannel: OtpChannel.email,
      otpPrefix: '732-',
    );
  }

  @override
  Future<AuthTicket> submitOtp({
    required String userName,
    required String password,
    required int lcid,
    required String otp,
  }) async {
    return const AuthTicket(
      step: NeptunAuthStep.authenticated,
      accessToken: 'jwt',
      neptunCode: 'ABC123',
    );
  }

  @override
  Future<AuthTicket> resendEmailCode({
    required String userName,
    required String password,
    required int lcid,
  }) {
    return submitPassword(userName: userName, password: password, lcid: lcid);
  }
}

void main() {
  testWidgets('Verification shows Send code again for email channel',
      (tester) async {
    final controller = AuthController(
      store: MemorySecureStore(),
      prefs: MemoryPrefsStore(),
      authApi: _EmailOtpAuth(),
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
      find.textContaining('authenticator is temporarily off'),
      findsNothing,
    );

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Send code again'));
    await tester.pump();

    expect(find.text('123456'), findsNothing);
    expect(find.text('A new code was requested.'), findsOneWidget);
    expect(find.textContaining('Send again in'), findsOneWidget);
  });
}
