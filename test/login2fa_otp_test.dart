import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/api/elte_portal_login.dart';
import 'package:karmin/api/exceptions.dart';
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

const _chooserSetvalForm = '''
<form action="/Account/Login2FA" method="post">
  <input name="__RequestVerificationToken" value="t" />
  <input type="hidden" id="Phase" name="Phase" value="SelectMethod" />
  <button type="submit" class="btn btn-primary" data-setval-target="Phase" data-setval-value="RequestTOTP">Authenticator</button>
  <button type="submit" class="btn btn-secondary" data-setval-target="Phase" data-setval-value="RequestEmail">E-mail code</button>
</form>
''';

const _chooserProviderForm = '''
<form action="/Account/Login2FA" method="post">
  <input name="__RequestVerificationToken" value="t" />
  <input name="Phase" value="RequestTOTP" />
  <input id="TOTPCode" name="TOTPCode" value="" />
  <button type="submit" class="btn btn-primary">Log in</button>
  <button type="submit" name="Provider" value="Email" class="btn btn-secondary">E-mail kód</button>
</form>
''';

const _emailFormAfterSend = '''
<form action="/Account/Login2FA" method="post">
  <input name="__RequestVerificationToken" value="t2" />
  <input name="Phase" value="RequestEmail" />
  <span class="input-group-text">774-</span>
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

  test('data-setval E-mail code button sets Phase=RequestEmail', () {
    final button = findLogin2FaEmailSendControl(_chooserSetvalForm);
    expect(button, isNotNull);
    expect(button!.setvalTarget, 'Phase');
    expect(button.setvalValue, 'RequestEmail');
    final posted = fillLogin2FaSendEmailFields(
      fields: extractNamedInputs(_chooserSetvalForm),
      button: button,
    );
    expect(posted['Phase'], 'RequestEmail');
    expect(posted['__RequestVerificationToken'], 't');
    expect(posted.containsKey('TOTPCode'), isFalse);
  });

  test('Provider=Email button is the send-mail control on RequestTOTP', () {
    final button = findLogin2FaEmailSendControl(_chooserProviderForm);
    expect(button, isNotNull);
    expect(button!.name, 'Provider');
    expect(button.value, 'Email');
    final posted = fillLogin2FaSendEmailFields(
      fields: extractNamedInputs(_chooserProviderForm),
      button: button,
    );
    expect(posted['Provider'], 'Email');
    expect(posted['Phase'], 'RequestTOTP');
  });

  test('fallback send-email POST forces Provider=Email and Phase=RequestEmail', () {
    final posted = fillLogin2FaSendEmailFields(
      fields: {'__RequestVerificationToken': 't', 'Phase': 'RequestTOTP'},
    );
    expect(posted['Provider'], 'Email');
    expect(posted['Phase'], 'RequestEmail');
  });

  test('Login2FA POST concatenates span prefix with the typed tail', () async {
    Map<String, String>? posted;
    final adapter = ScriptedAdapter(
      eltePortalScript(
        login2faHtml: _spanForm,
        onRequest: (options) {
          if (options.method == 'POST' &&
              isLogin2FaUrl(options.uri.toString())) {
            final data = options.data;
            if (data is String) {
              posted = Uri.splitQueryString(data);
            } else if (data is Map) {
              posted = data.map((key, value) => MapEntry('$key', '$value'));
            }
          }
        },
      ),
    );

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

  test('prefix already on Login2FA does not POST send-email', () async {
    var login2faPosts = 0;
    final adapter = ScriptedAdapter(
      eltePortalScript(
        login2faHtml: _spanForm,
        onRequest: (options) {
          if (options.method == 'POST' &&
              isLogin2FaUrl(options.uri.toString())) {
            login2faPosts += 1;
          }
        },
      ),
    );
    final ticket = await LiveNeptunAuth(clientWith(adapter)).submitPassword(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.otpPrefix, _prefix);
    expect(login2faPosts, 0);
  });

  test('chooser Login2FA POSTs E-mail code before showing the prefix', () async {
    final sendPosts = <Map<String, String>>[];
    var login2faHtml = _chooserSetvalForm;
    final adapter = ScriptedAdapter((options) {
      final url = options.uri.toString();
      if (url.contains('Account/Authenticate')) {
        return jsonBody(400, {});
      }
      if (options.method == 'GET' && isLogin2FaUrl(url)) {
        return htmlBody(200, login2faHtml);
      }
      if (options.method == 'GET' && isPasswordLoginUrl(url)) {
        return htmlBody(200, eltePasswordLoginHtml);
      }
      if (options.method == 'POST' && isLogin2FaUrl(url)) {
        final posted = Uri.splitQueryString(options.data as String);
        sendPosts.add(posted);
        expect(posted['Phase'], 'RequestEmail');
        expect(posted['__RequestVerificationToken'], 't');
        login2faHtml = _emailFormAfterSend;
        return htmlBody(200, _emailFormAfterSend);
      }
      if (options.method == 'POST' && isPasswordLoginUrl(url)) {
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
    expect(ticket.otpPrefix, '774-');
    expect(ticket.otpChannel, OtpChannel.email);
    expect(sendPosts, hasLength(1));
  });

  test('resend POSTs Login2FA send-email, not a no-op GET or JSON Authenticate',
      () async {
    var loginPosts = 0;
    var login2faPosts = 0;
    var authenticatePosts = 0;
    var login2faHtml = _chooserProviderForm;
    final sendBodies = <String>[];

    final adapter = ScriptedAdapter((options) {
      final url = options.uri.toString();
      if (url.contains('Account/Authenticate')) {
        authenticatePosts += 1;
        return jsonBody(400, {});
      }
      if (options.method == 'GET' && isLogin2FaUrl(url)) {
        return htmlBody(200, login2faHtml);
      }
      if (options.method == 'GET' && isPasswordLoginUrl(url)) {
        return htmlBody(200, eltePasswordLoginHtml);
      }
      if (options.method == 'POST' && isLogin2FaUrl(url)) {
        login2faPosts += 1;
        expect(options.data, isA<String>());
        sendBodies.add(options.data as String);
        login2faHtml = _emailFormAfterSend.replaceAll('774-', '881-');
        return htmlBody(200, login2faHtml);
      }
      if (options.method == 'POST' && isPasswordLoginUrl(url)) {
        loginPosts += 1;
        return htmlBody(302, '', location: '/Account/Login2FA');
      }
      fail('unexpected ${options.method} $url');
    });

    final auth = LiveNeptunAuth(clientWith(adapter));
    final first = await auth.submitPassword(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    expect(first.otpPrefix, '881-');
    expect(loginPosts, 1);
    expect(login2faPosts, 1);
    expect(sendBodies.first, contains('Provider=Email'));
    expect(authenticatePosts, 1);

    login2faHtml = _emailFormAfterSend.replaceAll('774-', '881-');
    final again = await auth.resendEmailCode(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    expect(again.step, NeptunAuthStep.needsOtp);
    expect(again.otpPrefix, '881-');
    expect(again.otpChannel, OtpChannel.email);
    expect(loginPosts, 1);
    expect(login2faPosts, 2);
    expect(authenticatePosts, 1);
  });

  test('failed send-email POST is a visible error, not a silent OTP screen',
      () async {
    final adapter = ScriptedAdapter((options) {
      final url = options.uri.toString();
      if (url.contains('Account/Authenticate')) {
        return jsonBody(400, {});
      }
      if (options.method == 'GET' && isLogin2FaUrl(url)) {
        return htmlBody(200, _chooserSetvalForm);
      }
      if (options.method == 'GET' && isPasswordLoginUrl(url)) {
        return htmlBody(200, eltePasswordLoginHtml);
      }
      if (options.method == 'POST' && isLogin2FaUrl(url)) {
        return htmlBody(200, _chooserSetvalForm);
      }
      if (options.method == 'POST' && isPasswordLoginUrl(url)) {
        return htmlBody(302, '', location: '/Account/Login2FA');
      }
      fail('unexpected ${options.method} $url');
    });

    await expectLater(
      LiveNeptunAuth(clientWith(adapter)).submitPassword(
        userName: 'abc123',
        password: 'secret',
        lcid: 1033,
      ),
      throwsA(isA<NeptunEmailCodeException>()),
    );
  });

  test('bare 6-digit TOTP is not posted to the email Login2FA form', () async {
    var login2faPosts = 0;
    final adapter = ScriptedAdapter((options) {
      if (options.method == 'POST' && isLogin2FaUrl(options.uri.toString())) {
        login2faPosts += 1;
      }
      return eltePortalScript()(options);
    });
    final portal = EltePortalLogin(clientWith(adapter));
    await expectLater(
      portal.submitOtp(otp: '123456'),
      throwsA(isA<NeptunOtpException>()),
    );
    expect(login2faPosts, 0);
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
    expect(
      find.text(
        'This build uses the email code only; authenticator is temporarily off.',
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), _tail);
    expect(find.text(_tail), findsOneWidget);
  });
}
