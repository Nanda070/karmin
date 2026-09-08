import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/api/elte_portal_login.dart';
import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_auth.dart';
import 'package:karmin/api/neptun_client.dart';
import 'package:karmin/auth/auth_models.dart';

class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.onFetch);

  final ResponseBody Function(RequestOptions options) onFetch;
  int calls = 0;
  final paths = <String>[];
  final bodies = <dynamic>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    paths.add(options.uri.toString());
    bodies.add(options.data);
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(int status, Object? body) {
  return ResponseBody.fromString(
    body is String ? body : jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

ResponseBody htmlBody(
  int status,
  String html, {
  String? location,
}) {
  return ResponseBody.fromString(
    html,
    status,
    headers: {
      Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      if (location != null) 'location': [location],
    },
  );
}

NeptunClient clientWith(ScriptedAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: NeptunClient.baseUrl,
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    ),
  );
  dio.httpClientAdapter = adapter;
  return NeptunClient(dio: dio);
}

void main() {
  group('parseAuthenticateResponse', () {
    test('HTTP 202 with isTwoFactorRequired is OTP, never invalidCredentials', () {
      final ticket = parseAuthenticateResponse(
        statusCode: 202,
        data: {
          'data': {
            'accessToken': null,
            'isTwoFactorRequired': true,
            'isCaptchaRequired': false,
            'twoFactorType': 'email',
          },
        },
      );
      expect(ticket.step, NeptunAuthStep.needsOtp);
      expect(ticket.otpChannel, OtpChannel.email);
      expect(ticket.hasJwt, isFalse);
    });

    test('HTTP 202 without flags is still OTP, never invalidCredentials', () {
      final ticket = parseAuthenticateResponse(statusCode: 202, data: {});
      expect(ticket.step, NeptunAuthStep.needsOtp);
      expect(ticket.hasJwt, isFalse);
    });

    test('HTTP 400 with 2FA flags is OTP, never invalidCredentials', () {
      final ticket = parseAuthenticateResponse(
        statusCode: 400,
        data: {
          'IsTwoFactorRequired': true,
          'AccessToken': null,
        },
      );
      expect(ticket.step, NeptunAuthStep.needsOtp);
    });

    test('HTTP 400 with two-factor message is OTP', () {
      final ticket = parseAuthenticateResponse(
        statusCode: 400,
        data: {'message': 'Two-factor authentication required'},
      );
      expect(ticket.step, NeptunAuthStep.needsOtp);
    });

    test('HTTP 401 with 2FA string flag is OTP', () {
      final ticket = parseAuthenticateResponse(
        statusCode: 401,
        data: {'isTwoFactorRequired': 'true'},
      );
      expect(ticket.step, NeptunAuthStep.needsOtp);
    });

    test('HTTP 202 captcha is distinct from credentials', () {
      expect(
        () => parseAuthenticateResponse(
          statusCode: 202,
          data: {'isCaptchaRequired': true, 'accessToken': null},
        ),
        throwsA(isA<NeptunCaptchaException>()),
      );
    });

    test('HTTP 400 captcha is distinct from credentials', () {
      expect(
        () => parseAuthenticateResponse(
          statusCode: 400,
          data: {'IsCaptchaRequired': 1},
        ),
        throwsA(isA<NeptunCaptchaException>()),
      );
    });

    test('empty HTTP 400 is unavailable, not invalidCredentials', () {
      expect(
        () => parseAuthenticateResponse(statusCode: 400, data: {}),
        throwsA(isA<NeptunUnavailableException>()),
      );
    });

    test('HTML 404 is unavailable, not invalidCredentials', () {
      expect(
        () => parseAuthenticateResponse(
          statusCode: 404,
          data: '<!DOCTYPE html><html><body>Not found</body></html>',
        ),
        throwsA(isA<NeptunUnavailableException>()),
      );
    });

    test('real bad password JSON 400 is invalidCredentials', () {
      expect(
        () => parseAuthenticateResponse(
          statusCode: 400,
          data: {
            'modelStateErrors': [
              {
                'errors': ['Invalid user name or password.'],
              },
            ],
          },
        ),
        throwsA(isA<NeptunAuthException>()),
      );
    });

    test('HTTP 429 is lockout, not invalidCredentials', () {
      expect(
        () => parseAuthenticateResponse(statusCode: 429, data: {}),
        throwsA(isA<NeptunLockoutException>()),
      );
    });
  });

  test('authenticate JSON body uppercases the code and omits token', () {
    final body = authenticateJsonBody(
      userName: 'n4ibzj',
      password: 'secret',
      lcid: 1038,
    );
    expect(body['userName'], 'N4IBZJ');
    expect(body['password'], 'secret');
    expect(body['lcid'], 1038);
    expect(body['captcha'], '');
    expect(body.containsKey('token'), isFalse);
  });

  test('live 400 + 2FA is OTP and never invalidCredentials', () async {
    final adapter = ScriptedAdapter(
      (options) => jsonBody(400, {
        'data': {
          'isTwoFactorRequired': true,
          'isCaptchaRequired': false,
        },
      }),
    );
    final auth = LiveNeptunAuth(clientWith(adapter));
    final ticket = await auth.submitPassword(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
    expect(adapter.calls, 1);
    expect(adapter.paths.single.contains('Account/Authenticate'), isTrue);
  });

  test('live 202 without data envelope is OTP, not invalidCredentials', () async {
    final adapter = ScriptedAdapter(
      (options) => jsonBody(202, {'isTwoFactorRequired': true}),
    );
    final ticket = await LiveNeptunAuth(clientWith(adapter)).submitPassword(
      userName: 'abc',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
  });

  test('JSON API miss falls back to ELTE MVC Login2FA', () async {
    final adapter = ScriptedAdapter((options) {
      final url = options.uri.toString();
      if (url.contains('Account/Authenticate')) {
        return jsonBody(400, {});
      }
      if (options.method == 'GET' && url.contains('Account/Login2FA')) {
        return htmlBody(
          200,
          '<form><input name="__RequestVerificationToken" value="t" />'
          '<input name="TOTPCode" value="" />'
          '<input name="Phase" value="RequestTOTP" /></form>',
        );
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
      if (options.method == 'POST' && url.contains('Account/Login')) {
        return htmlBody(302, '', location: '/Account/Login2FA');
      }
      fail('unexpected ${options.method} $url');
    });
    final ticket = await LiveNeptunAuth(clientWith(adapter)).submitPassword(
      userName: 'n4ibzj',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
    expect(adapter.paths.any((path) => path.contains('Account/Login')), isTrue);
  });

  test('portal form helpers read hidden fields and cookies', () {
    final html =
        '<input type="hidden" name="__RequestVerificationToken" value="abc" />'
        '<input name="LoginName" />';
    final fields = extractNamedInputs(html);
    expect(fields['__RequestVerificationToken'], 'abc');
    expect(fields['LoginName'], '');
    expect(htmlLooksLikeOtp('<input id="TOTPCode" name="TOTPCode" />'), isTrue);
    final jar = <String, String>{};
    mergeSetCookie(jar, ['.Potlap.Session=xyz; path=/; httponly']);
    expect(cookieHeader(jar), '.Potlap.Session=xyz');
  });
}
