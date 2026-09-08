import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/api/elte_portal_login.dart';
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

import 'neptun_auth_test.dart';

const _prefix = '732-';
const _tail = '893600';
const _composed = '732-893600';

const _spanForm = '''
<form action="/Account/Login2FA" method="post">
  <input name="__RequestVerificationToken" value="t" />
  <input name="Phase" value="RequestTOTP" />
  <label>E-mail code</label>
  <div class="input-group">
    <span class="input-group-text">732-</span>
    <input id="TOTPCode" name="TOTPCode" value="" />
  </div>
</form>
''';

const _hiddenPrefixForm = '''
<form action="/Account/Login2FA" method="post">
  <input name="__RequestVerificationToken" value="t" />
  <input name="Phase" value="RequestTOTP" />
  <input name="Prefix" value="732-" />
  <input id="TOTPCode" name="TOTPCode" value="" />
</form>
''';

void main() {
  test('span prefix 732- plus tail 893600 composes 732-893600', () {
    expect(parseLogin2FaPrefix(_spanForm), _prefix);
    expect(
      composeLogin2FaCode(prefix: _prefix, tail: _tail),
      _composed,
    );
    final posted = fillLogin2FaOtpFields(
      fields: extractNamedInputs(_spanForm),
      prefix: _prefix,
      tail: _tail,
    );
    expect(posted['TOTPCode'], _composed);
    expect(posted['Phase'], 'RequestTOTP');
    expect(posted['__RequestVerificationToken'], 't');
  });

  test('named Prefix field keeps prefix and posts only the tail', () {
    expect(parseLogin2FaPrefix(_hiddenPrefixForm), _prefix);
    final posted = fillLogin2FaOtpFields(
      fields: extractNamedInputs(_hiddenPrefixForm),
      prefix: _prefix,
      tail: _tail,
    );
    expect(posted['Prefix'], _prefix);
    expect(posted['TOTPCode'], _tail);
  });

  test('6-digit authenticator codes stay unchanged', () {
    expect(composeLogin2FaCode(prefix: '', tail: '123456'), '123456');
    final posted = fillLogin2FaOtpFields(
      fields: {'TOTPCode': '', 'Phase': 'RequestTOTP'},
      prefix: '',
      tail: '123456',
    );
    expect(posted['TOTPCode'], '123456');
  });

  test('disabled prefix input is parsed', () {
    const html =
        '<input value="774-" disabled="disabled" />'
        '<input name="TOTPCode" value="" />';
    expect(parseLogin2FaPrefix(html), '774-');
  });

  test('pasting the full email code does not double the prefix', () {
    expect(
      composeLogin2FaCode(prefix: _prefix, tail: _composed),
      _composed,
    );
  });

  test('JSON 2FA payload can carry the prefix', () {
    final ticket = parseAuthenticateResponse(
      statusCode: 202,
      data: {
        'isTwoFactorRequired': true,
        'twoFactorType': 'email',
        'codePrefix': '732-',
      },
    );
    expect(ticket.otpPrefix, _prefix);
    expect(ticket.otpChannel, OtpChannel.email);
  });

  test('Login2FA POST concatenates span prefix with the typed tail', () async {
    Map<String, String>? posted;
    final adapter = ScriptedAdapter((options) {
      final url = options.uri.toString();
      if (url.contains('Account/Authenticate')) {
        return jsonBody(400, {});
      }
      if (options.method == 'GET' && url.contains('Account/Login2FA')) {
        return htmlBody(200, _spanForm);
      }
      if (options.method == 'GET' && url.contains('Account/Login')) {
        return htmlBody(
          200,
          '<form method="post">'
          '<input name="__RequestVerificationToken" value="tok" />'
          '<input name="LoginName" value="" />'
          '<input name="Password" value="" />'
          '</form>',
        );
      }
      if (options.method == 'POST' && url.contains('Account/Login2FA')) {
        final data = options.data;
        if (data is Map) {
          posted = data.map((key, value) => MapEntry('$key', '$value'));
        }
        return htmlBody(302, '', location: '/');
      }
      if (options.method == 'POST' && url.contains('Account/Login')) {
        return htmlBody(302, '', location: '/Account/Login2FA');
      }
      fail('unexpected ${options.method} $url');
    });

    final auth = LiveNeptunAuth(clientWith(adapter));
    final ticket = await auth.submitPassword(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
    expect(ticket.otpPrefix, _prefix);
    expect(ticket.otpChannel, OtpChannel.email);

    final done = await auth.submitOtp(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
      otp: _tail,
    );
    expect(done.step, NeptunAuthStep.authenticated);
    expect(posted, isNotNull);
    expect(posted!['TOTPCode'], _composed);
    expect(posted!['Phase'], 'RequestTOTP');
  });

  testWidgets('OTP screen shows read-only prefix and asks only for the tail',
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
    controller.debugSetState(
      controller.state.copyWith(
        otpChannel: OtpChannel.email,
        otpPrefix: _prefix,
      ),
    );

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

    expect(find.text(_prefix), findsOneWidget);
    expect(
      find.text(
        'Enter the code after the dash; the prefix is filled by Neptun.',
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), _tail);
    expect(find.text(_tail), findsOneWidget);
  });
}
