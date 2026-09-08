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

const _totpForm = '''
<form action="/Account/Login2FA" method="post">
  <input name="__RequestVerificationToken" value="t" />
  <input name="Phase" value="RequestTOTP" />
  <input name="HasTOTP" value="True" />
  <input name="HasEmail" value="True" />
  <input name="NeptunCode" value="ABC123" />
  <input name="Key" value="session-key" />
  <input name="Rendered" value="r" />
  <input name="CodePrefix" value="" />
  <input id="TOTPCode" name="TOTPCode" value="" />
</form>
''';

const _emailFormAfterSend = '''
<form action="/Account/Login2FA" method="post">
  <input name="__RequestVerificationToken" value="t2" />
  <input name="Phase" value="RequestEmailCode" />
  <input name="HasTOTP" value="True" />
  <input name="HasEmail" value="True" />
  <input name="NeptunCode" value="ABC123" />
  <input name="Key" value="session-key" />
  <input name="Rendered" value="r" />
  <input name="CodePrefix" value="774-" />
  <input id="EmailCode" name="EmailCode" value="" />
</form>
''';

void main() {
  test('authenticateJsonBody matches Neptun-Mobile-fork fields', () {
    final body = authenticateJsonBody(
      userName: 'abc123',
      password: 'secret',
      lcid: 1038,
    );
    expect(body['userName'], 'ABC123');
    expect(body['password'], 'secret');
    expect(body['captcha'], '');
    expect(body['captchaIdentifier'], '');
    expect(body['token'], '');
    expect(body['LCID'], 1038);

    final withOtp = authenticateJsonBody(
      userName: 'abc123',
      password: 'secret',
      lcid: 1038,
      otp: '123456',
    );
    expect(withOtp['token'], '123456');
  });

  test('GetEmail=true keeps Phase (Neptun-Mobile / fork sibling evidence)', () {
    final posted = fillLogin2FaSendEmailFields(
      fields: extractNamedInputs(_totpForm),
    );
    expect(posted['GetEmail'], 'true');
    expect(posted['Phase'], 'RequestTOTP');
    expect(posted['HasEmail'], 'True');
    expect(posted['CodePrefix'], '');
    expect(posted.containsKey('Provider'), isFalse);
    expect(posted.containsKey('TOTPCode'), isFalse);
  });

  test('TOTP verify posts RequestTOTP + TOTPCode', () {
    final posted = fillLogin2FaOtpFields(
      fields: extractNamedInputs(_totpForm),
      prefix: '',
      tail: '123456',
      isTotp: true,
    );
    expect(posted['Phase'], 'RequestTOTP');
    expect(posted['TOTPCode'], '123456');
    expect(posted.containsKey('EmailCode'), isFalse);
  });

  test('email verify posts RequestEmailCode + EmailCode + CodePrefix', () {
    final posted = fillLogin2FaOtpFields(
      fields: extractNamedInputs(_emailFormAfterSend),
      prefix: '774-',
      tail: '893600',
      isTotp: false,
    );
    expect(posted['Phase'], 'RequestEmailCode');
    expect(posted['EmailCode'], '893600');
    expect(posted['CodePrefix'], '774-');
    expect(posted.containsKey('TOTPCode'), isFalse);
  });

  test('compose helpers still support display prefix', () {
    expect(composeLogin2FaCode(prefix: _prefix, tail: _tail), _composed);
    expect(composeLogin2FaCode(prefix: '', tail: '123456'), '123456');
  });

  test('JSON 2FA payload prefers authenticator when type is app', () {
    final ticket = parseAuthenticateResponse(
      statusCode: 202,
      data: {
        'isTwoFactorRequired': true,
        'twoFactorType': 'totp',
        'twoFactorLoginToken': 'pending',
      },
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
    expect(ticket.otpChannel, OtpChannel.authenticator);
  });

  test('MVC password with TOTP form does not require email prefix', () async {
    Map<String, String>? lastPost;
    final adapter = ScriptedAdapter(
      eltePortalScript(
        login2faHtml: _totpForm,
        onRequest: (options) {
          if (options.method == 'POST' &&
              isLogin2FaUrl(options.uri.toString())) {
            final data = options.data;
            if (data is String) {
              lastPost = Uri.splitQueryString(data);
            }
          }
        },
      ),
    );

    final auth = EltePortalLogin(clientWith(adapter));
    final ticket = await auth.submitPassword(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
    expect(ticket.otpChannel, OtpChannel.authenticator);
    expect(normalizeOtpPrefix(ticket.otpPrefix), isEmpty);

    final done = await auth.submitOtp(otp: '123456');
    expect(done.step, NeptunAuthStep.authenticated);
    expect(lastPost, isNotNull);
    expect(lastPost!['Phase'], 'RequestTOTP');
    expect(lastPost!['TOTPCode'], '123456');
  });

  test('stale dual-UI email prefix does not glue onto TOTP verify', () async {
    // Dual Login2FA: TOTP fields + grey 732- span (pollutes parseLogin2FaPrefix).
    const dualHtml = '''
<form action="/Account/Login2FA" method="post">
  <input name="__RequestVerificationToken" value="t" />
  <input name="Phase" value="RequestTOTP" />
  <input name="HasTOTP" value="True" />
  <input name="HasEmail" value="True" />
  <input name="NeptunCode" value="ABC123" />
  <input name="Key" value="session-key" />
  <input name="Rendered" value="r" />
  <input name="CodePrefix" value="" />
  <span class="input-group-text">732-</span>
  <input id="TOTPCode" name="TOTPCode" value="" />
</form>
''';
    Map<String, String>? lastPost;
    final adapter = ScriptedAdapter(
      eltePortalScript(
        login2faHtml: dualHtml,
        onRequest: (options) {
          if (options.method == 'POST' &&
              isLogin2FaUrl(options.uri.toString())) {
            final data = options.data;
            if (data is String) {
              lastPost = Uri.splitQueryString(data);
            }
          }
        },
      ),
    );

    final auth = EltePortalLogin(clientWith(adapter));
    await auth.submitPassword(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    final done = await auth.submitOtp(otp: '654321');
    expect(done.step, NeptunAuthStep.authenticated);
    expect(lastPost!['Phase'], 'RequestTOTP');
    expect(lastPost!['TOTPCode'], '654321');
    expect(lastPost!['CodePrefix'], '');
    expect(lastPost!.containsKey('EmailCode'), isFalse);
  });

  test('submitOtp always GETs Login2FA before POST (fresh antiforgery)', () async {
    var login2faGets = 0;
    var login2faPosts = 0;
    final adapter = ScriptedAdapter(
      eltePortalScript(
        login2faHtml: _totpForm,
        onRequest: (options) {
          if (!isLogin2FaUrl(options.uri.toString())) {
            return;
          }
          if (options.method == 'GET') {
            login2faGets += 1;
          }
          if (options.method == 'POST') {
            login2faPosts += 1;
          }
        },
      ),
    );

    final auth = EltePortalLogin(clientWith(adapter));
    await auth.submitPassword(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    final getsAfterPassword = login2faGets;
    await auth.submitOtp(otp: '123456');
    expect(login2faGets, greaterThan(getsAfterPassword));
    expect(login2faPosts, 1);
  });

  test('empty OTP digits throw NeptunOtpException immediately', () async {
    final auth = LiveNeptunAuth(
      clientWith(
        ScriptedAdapter((options) {
          fail('empty OTP must not hit the network');
        }),
      ),
    );
    expect(
      () => auth.submitOtp(
        userName: 'abc123',
        password: 'secret',
        lcid: 1033,
        otp: '   ---',
      ),
      throwsA(isA<NeptunOtpException>()),
    );
  });

  test('optional GetEmail via resend → email channel with prefix', () async {
    var login2faHtml = _totpForm;
    final sendPosts = <Map<String, String>>[];
    final adapter = ScriptedAdapter((options) {
      final url = options.uri.toString();
      if (url.contains('Account/Authenticate')) {
        return jsonBody(202, {'isTwoFactorRequired': true});
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
        expect(posted['GetEmail'], 'true');
        expect(posted['Phase'], 'RequestTOTP');
        login2faHtml = _emailFormAfterSend;
        return htmlBody(200, _emailFormAfterSend);
      }
      if (options.method == 'POST' && isPasswordLoginUrl(url)) {
        return htmlBody(302, '', location: '/Account/Login2FA?Key=session-key');
      }
      fail('unexpected ${options.method} $url');
    });

    final auth = LiveNeptunAuth(clientWith(adapter));
    final first = await auth.submitPassword(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    expect(first.otpChannel, OtpChannel.authenticator);
    expect(normalizeOtpPrefix(first.otpPrefix), isEmpty);
    expect(sendPosts, isEmpty);

    final ticket = await auth.resendEmailCode(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.otpChannel, OtpChannel.email);
    expect(ticket.otpPrefix, '774-');
    expect(sendPosts, isNotEmpty);
  });

  test('password Login2FA with dual UI span stays authenticator (no GetEmail)',
      () async {
    final adapter = ScriptedAdapter((options) {
      final url = options.uri.toString();
      if (url.contains('Account/Authenticate')) {
        return jsonBody(202, {'isTwoFactorRequired': true});
      }
      if (options.method == 'GET' && isLogin2FaUrl(url)) {
        return htmlBody(200, _totpForm);
      }
      if (options.method == 'GET' && isPasswordLoginUrl(url)) {
        return htmlBody(200, eltePasswordLoginHtml);
      }
      if (options.method == 'POST' && isLogin2FaUrl(url)) {
        fail('password must not auto-POST Login2FA GetEmail');
      }
      if (options.method == 'POST' && isPasswordLoginUrl(url)) {
        return htmlBody(302, '', location: '/Account/Login2FA');
      }
      fail('unexpected ${options.method} $url');
    });

    final ticket = await EltePortalLogin(clientWith(adapter)).submitPassword(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
    expect(ticket.otpChannel, OtpChannel.authenticator);
    expect(normalizeOtpPrefix(ticket.otpPrefix), isEmpty);
  });

  test('fork-style Authenticate 2FA then token verify', () async {
    var sawToken = false;
    final adapter = ScriptedAdapter((options) {
      final url = options.uri.toString();
      if (options.method == 'POST' &&
          url.contains('/Account/api/Account/Authenticate')) {
        final map = asAuthBody(options.data);
        final token = '${map['token'] ?? ''}';
        expect(map.containsKey('lcid'), isFalse);
        expect(map['LCID'], 1038);
        if (token.isEmpty) {
          return jsonBody(202, {
            'data': {
              'isTwoFactorRequired': true,
              'twoFactorLoginToken': 'pending-2fa',
            },
          });
        }
        sawToken = true;
        expect(token, '654321');
        return jsonBody(200, {
          'data': {'accessToken': 'jwt-from-fork'},
        });
      }
      if (url.contains('Account/Authenticate')) {
        return jsonBody(202, {'isTwoFactorRequired': true});
      }
      fail('unexpected ${options.method} $url');
    });

    final auth = LiveNeptunAuth(clientWith(adapter));
    final first = await auth.submitPassword(
      userName: 'abc123',
      password: 'secret',
      lcid: 1038,
    );
    expect(first.step, NeptunAuthStep.needsOtp);
    expect(first.otpChannel, OtpChannel.authenticator);
    expect(normalizeOtpPrefix(first.otpPrefix), isEmpty);

    final done = await auth.submitOtp(
      userName: 'abc123',
      password: 'secret',
      lcid: 1038,
      otp: '654321',
    );
    expect(sawToken, isTrue);
    expect(done.step, NeptunAuthStep.authenticated);
    expect(done.accessToken, 'jwt-from-fork');
  });

  test('controller does not compose email prefix onto authenticator TOTP',
      () async {
    String? seenOtp;
    final controller = AuthController(
      store: MemorySecureStore(),
      prefs: MemoryPrefsStore(),
      authApi: _CapturingAuth(
        onPassword: () => const AuthTicket(
          step: NeptunAuthStep.needsOtp,
          otpChannel: OtpChannel.authenticator,
          otpPrefix: '732-',
        ),
        onOtp: (otp) {
          seenOtp = otp;
          return const AuthTicket(
            step: NeptunAuthStep.authenticated,
            accessToken: 'jwt',
            neptunCode: 'ABC123',
          );
        },
      ),
      client: NeptunClient(),
      localAuth: LocalAuthProbe(),
      usingDebugAuth: true,
      hydrateOnStart: false,
    );
    await controller.acceptDisclaimer();
    await controller.login(userName: 'abc123', password: 'secret', lcid: 1038);
    expect(controller.state.otpChannel, OtpChannel.authenticator);
    expect(controller.state.otpPrefix, isEmpty);

    await controller.submitOtp(otp: '654321', lcid: 1038);
    expect(seenOtp, '654321');
  });

  testWidgets('OTP screen shows authenticator hint without email-parked copy',
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

    expect(
      find.text('Enter the one-time code from your authenticator app.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('authenticator is temporarily off'),
      findsNothing,
    );
    expect(find.text('Send code again'), findsNothing);
  });
}

class _CapturingAuth implements NeptunAuthApi {
  _CapturingAuth({
    this.onPassword,
    required this.onOtp,
  });

  final AuthTicket Function()? onPassword;
  final AuthTicket Function(String otp) onOtp;

  @override
  Future<AuthTicket> submitPassword({
    required String userName,
    required String password,
    required int lcid,
  }) async {
    return onPassword?.call() ??
        const AuthTicket(
          step: NeptunAuthStep.needsOtp,
          otpChannel: OtpChannel.authenticator,
        );
  }

  @override
  Future<AuthTicket> submitOtp({
    required String userName,
    required String password,
    required int lcid,
    required String otp,
  }) async {
    return onOtp(otp);
  }

  @override
  Future<AuthTicket> resendEmailCode({
    required String userName,
    required String password,
    required int lcid,
  }) {
    return submitPassword(userName: userName, password: password, lcid: lcid);
  }

  @override
  void reset() {}
}
