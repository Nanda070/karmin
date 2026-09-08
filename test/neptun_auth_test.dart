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
  final headers = <Map<String, dynamic>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    paths.add(options.uri.toString());
    bodies.add(options.data);
    headers.add(Map<String, dynamic>.from(options.headers));
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(
  int status,
  Object? body, {
  List<String>? setCookie,
}) {
  return ResponseBody.fromString(
    body is String ? body : jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      if (setCookie != null) 'set-cookie': setCookie,
    },
  );
}

ResponseBody htmlBody(
  int status,
  String html, {
  String? location,
  List<String>? setCookie,
}) {
  return ResponseBody.fromString(
    html,
    status,
    headers: {
      Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      if (location != null) 'location': [location],
      if (setCookie != null) 'set-cookie': setCookie,
    },
  );
}

NeptunClient clientWith(ScriptedAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: NeptunClient.baseUrl,
      headers: const {
        'User-Agent': NeptunClient.userAgent,
        'Accept': 'application/json, text/plain, */*',
        'X-Requested-With': 'XMLHttpRequest',
      },
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    ),
  );
  dio.httpClientAdapter = adapter;
  return NeptunClient(dio: dio);
}

const eltePasswordLoginHtml = '''
<form method="post" id="selectLanguageForm" action="/Home/SetLanguage">
  <input type="hidden" name="returnUrl" value="/Account/Login" />
  <input type="hidden" name="culture" value="en" />
  <input name="__RequestVerificationToken" type="hidden" value="lang-token" />
</form>
<form action="/Account/Login" method="post">
  <input name="__RequestVerificationToken" value="login-token" />
  <input name="LoginName" value="" />
  <input name="Password" value="" />
  <input type="hidden" id="ReturnUrl" name="ReturnUrl" value="" />
</form>
''';

const elteLogin2FaHtml = '''
<form action="/Account/Login2FA" method="post">
  <input name="__RequestVerificationToken" value="otp-token" />
  <input name="Phase" value="RequestTOTP" />
  <label>E-mail code</label>
  <span class="input-group-text">732-</span>
  <input id="TOTPCode" name="TOTPCode" value="" />
</form>
''';

bool isLogin2FaUrl(String url) => url.contains('Account/Login2FA');

bool isPasswordLoginUrl(String url) =>
    url.contains('Account/Login') && !isLogin2FaUrl(url);

Map<String, dynamic> asAuthBody(dynamic data) {
  if (data is String && data.isNotEmpty) {
    final decoded = jsonDecode(data);
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
  }
  if (data is Map) {
    return data.map((key, value) => MapEntry('$key', value));
  }
  return {};
}

Map<String, String> _postedFields(Object? data) {
  if (data is String) {
    return Uri.splitQueryString(data);
  }
  if (data is Map) {
    return data.map((key, value) => MapEntry('$key', '$value'));
  }
  return {};
}

ResponseBody Function(RequestOptions options) eltePortalScript({
  String login2faHtml = elteLogin2FaHtml,
  void Function(RequestOptions options)? onRequest,
}) {
  return (options) {
    onRequest?.call(options);
    final url = options.uri.toString();
    if (url.contains('Account/Authenticate')) {
      return jsonBody(400, {});
    }
    if (options.method == 'GET' && isLogin2FaUrl(url)) {
      return htmlBody(200, login2faHtml);
    }
    if (options.method == 'GET' && isPasswordLoginUrl(url)) {
      return htmlBody(
        200,
        eltePasswordLoginHtml,
        setCookie: const [
          '.Potlap.Antiforgery=af; path=/; samesite=strict; httponly',
          '.Potlap.Session=sess; path=/; samesite=lax; httponly',
        ],
      );
    }
    if (options.method == 'POST' && isLogin2FaUrl(url)) {
      final posted = _postedFields(options.data);
      final totpDigits =
          (posted['TOTPCode'] ?? '').replaceAll(RegExp(r'\D'), '');
      if (totpDigits.length >= 6) {
        return htmlBody(302, '', location: '/');
      }
      return htmlBody(200, login2faHtml);
    }
    if (options.method == 'POST' && isPasswordLoginUrl(url)) {
      return htmlBody(302, '', location: '/Account/Login2FA');
    }
    fail('unexpected ${options.method} $url');
  };
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

    test('empty HTTP 400 is unavailable with HTTP status and empty-body snippet',
        () {
      expect(
        () => parseAuthenticateResponse(statusCode: 400, data: {}),
        throwsA(
          isA<NeptunUnavailableException>()
              .having(
                (e) => e.message,
                'message',
                contains('HTTP 400'),
              )
              .having(
                (e) => e.message,
                'snippet',
                contains('empty body'),
              ),
        ),
      );
    });

    test('HTML 404 is maintenance with status, not opaque OTP', () {
      expect(
        () => parseAuthenticateResponse(
          statusCode: 404,
          data: '<!DOCTYPE html><html><body>Not found</body></html>',
        ),
        throwsA(
          isA<NeptunMaintenanceException>().having(
            (e) => e.message,
            'message',
            contains('HTTP 404'),
          ),
        ),
      );
    });

    test('real bad password JSON 400 includes HTTP status', () {
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
        throwsA(
          isA<NeptunAuthException>().having(
            (e) => e.message,
            'message',
            contains('HTTP 400'),
          ),
        ),
      );
    });

    test('HTTP 429 is lockout, not invalidCredentials', () {
      expect(
        () => parseAuthenticateResponse(statusCode: 429, data: {}),
        throwsA(isA<NeptunLockoutException>()),
      );
    });

    test('OTP submit HTTP 400 includes status, not opaque default', () {
      expect(
        () => parseAuthenticateResponse(
          statusCode: 400,
          data: {
            'notification': {'message': 'Invalid token'},
          },
          forOtpSubmit: true,
        ),
        throwsA(
          isA<NeptunOtpException>().having(
            (e) => e.message,
            'message',
            'Neptun rejected this code (HTTP 400): Invalid token',
          ),
        ),
      );
    });

    test('OTP submit HTML is maintenance, not NeptunOtpException', () {
      expect(
        () => parseAuthenticateResponse(
          statusCode: 503,
          data: '<!DOCTYPE html><html><body>Maintenance</body></html>',
          forOtpSubmit: true,
        ),
        throwsA(isA<NeptunMaintenanceException>()),
      );
    });

    test('OTP submit 401 includes HTTP status', () {
      expect(
        () => parseAuthenticateResponse(
          statusCode: 401,
          data: {'message': 'Unauthorized'},
          forOtpSubmit: true,
        ),
        throwsA(
          isA<NeptunOtpException>().having(
            (e) => e.message,
            'message',
            contains('HTTP 401'),
          ),
        ),
      );
    });
  });

  test('empty Authenticate body snippet is explicit, never silent', () {
    expect(emptyAuthenticateBodySnippet(null), 'empty body');
    expect(emptyAuthenticateBodySnippet(''), 'empty body');
    expect(emptyAuthenticateBodySnippet(<String, dynamic>{}), 'empty body');
    expect(emptyAuthenticateBodySnippet({'message': 'x'}), isNull);
  });

  test('JSON probe uses the UI LCID once, not a 1033/1038 header retry list', () {
    expect(authenticateLcidForUi(1033), 1033);
    expect(authenticateLcidForUi(1038), 1038);
    expect(authenticateLcidForUi(1049), forkAuthenticateLcid);
  });

  test('generic ASP.NET 400 is unavailable, not bad password', () {
    expect(
      looksLikeInvalidCredentialsMessage('The request is invalid.'),
      isFalse,
    );
    expect(
      looksLikeInvalidCredentialsMessage('Invalid user name or password.'),
      isTrue,
    );
    expect(
      () => parseAuthenticateResponse(
        statusCode: 400,
        data: {'message': 'The request is invalid.'},
      ),
      throwsA(
        isA<NeptunUnavailableException>().having(
          (e) => e.message,
          'message',
          contains('HTTP 400'),
        ),
      ),
    );
  });

  test('authenticate JSON body matches fork key order + empty captcha/token', () {
    final body = authenticateJsonBody(
      userName: 'n4ibzj',
      password: 'secret',
    );
    expect(body.keys.toList(), [
      'userName',
      'password',
      'captcha',
      'captchaIdentifier',
      'token',
      'LCID',
    ]);
    expect(body['userName'], 'N4IBZJ');
    expect(body['password'], 'secret');
    expect(body['LCID'], forkAuthenticateLcid);
    expect(body['captcha'], '');
    expect(body['captchaIdentifier'], '');
    expect(body['token'], '');
    expect(jsonEncode(body), contains('"token":""'));
  });

  test('OTP body puts bare digits in token (fork submitTwoFactorCode)', () {
    final body = authenticateJsonBody(
      userName: 'abc',
      password: 'x',
      otp: '654321',
    );
    expect(body['token'], '654321');
    expect(body['LCID'], 1038);
  });

  test('fork device cookie header matches base64 UPPER username', () {
    final header = forkDeviceCookieHeader(
      userName: 'n4ibzj',
      cookieValue: 'cookieVal',
    );
    final b64 = base64.encode(utf8.encode('N4IBZJ'));
    expect(header, 'devicecookie-$b64=cookieVal');
    expect(
      extractDeviceCookieValue([
        'devicecookie-$b64=cookieVal; path=/; httponly',
      ]),
      'cookieVal',
    );
  });

  test('password login uses MVC Login and never POSTs JSON Authenticate',
      () async {
    var loginPosts = 0;
    final adapter = ScriptedAdapter((options) {
      final url = options.uri.toString();
      if (url.contains('Account/Authenticate')) {
        fail('password must not probe dead JSON Authenticate');
      }
      if (options.method == 'POST' && isPasswordLoginUrl(url)) {
        loginPosts += 1;
        return htmlBody(302, '', location: '/Account/Login2FA');
      }
      if (options.method == 'GET' && isLogin2FaUrl(url)) {
        return htmlBody(200, elteLogin2FaHtml);
      }
      if (options.method == 'GET' && isPasswordLoginUrl(url)) {
        return htmlBody(
          200,
          eltePasswordLoginHtml,
          setCookie: const [
            '.Potlap.Antiforgery=af; path=/; samesite=strict; httponly',
            '.Potlap.Session=sess; path=/; samesite=lax; httponly',
          ],
        );
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
    expect(ticket.otpChannel, OtpChannel.authenticator);
    expect(auth.jsonTwoFactorPending, isFalse);
    expect(loginPosts, 1);
  });

  test('Authenticate timeout does not become Can\'t reach before MVC Login',
      () async {
    final adapter = ScriptedAdapter((options) {
      final url = options.uri.toString();
      if (url.contains('Account/Authenticate')) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
      }
      return eltePortalScript()(options);
    });
    final ticket = await LiveNeptunAuth(clientWith(adapter)).submitPassword(
      userName: 'n4ibzj',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
    expect(
      adapter.paths.any((path) => path.contains('Account/Authenticate')),
      isFalse,
    );
  });

  test('MVC OTP after JSON miss posts Login2FA TOTP without email prefix',
      () async {
    Map<String, String>? totpPost;
    final adapter = ScriptedAdapter((options) {
      final url = options.uri.toString();
      if (url.contains('Account/Authenticate')) {
        return jsonBody(400, {});
      }
      if (options.method == 'GET' && isPasswordLoginUrl(url)) {
        return htmlBody(
          200,
          eltePasswordLoginHtml,
          setCookie: const [
            '.Potlap.Antiforgery=af; path=/; samesite=strict; httponly',
            '.Potlap.Session=sess; path=/; samesite=lax; httponly',
          ],
        );
      }
      if (options.method == 'POST' && isPasswordLoginUrl(url)) {
        return htmlBody(302, '', location: '/Account/Login2FA');
      }
      if (options.method == 'GET' && isLogin2FaUrl(url)) {
        return htmlBody(200, elteLogin2FaHtml);
      }
      if (options.method == 'POST' && isLogin2FaUrl(url)) {
        totpPost = _postedFields(options.data);
        return htmlBody(302, '', location: '/');
      }
      fail('unexpected ${options.method} $url');
    });
    final auth = LiveNeptunAuth(clientWith(adapter));
    final first = await auth.submitPassword(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    expect(first.step, NeptunAuthStep.needsOtp);
    expect(auth.jsonTwoFactorPending, isFalse);

    final done = await auth.submitOtp(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
      otp: '654321',
    );
    expect(done.step, NeptunAuthStep.authenticated);
    expect(totpPost, isNotNull);
    expect(totpPost!['TOTPCode'], '654321');
    expect(totpPost!['TOTPCode'], isNot(contains('732')));
  });

  test('MVC login error HTML is invalid credentials, not a second LCID probe',
      () async {
    final adapter = ScriptedAdapter((options) {
      final url = options.uri.toString();
      if (url.contains('Account/Authenticate')) {
        fail('password must not probe JSON Authenticate');
      }
      if (options.method == 'GET' && isPasswordLoginUrl(url)) {
        return htmlBody(200, eltePasswordLoginHtml);
      }
      if (options.method == 'POST' && isPasswordLoginUrl(url)) {
        return htmlBody(
          200,
          '$eltePasswordLoginHtml'
          '<div class="validation-summary-errors">Invalid user name or password.</div>',
        );
      }
      fail('unexpected ${options.method} $url');
    });
    final auth = LiveNeptunAuth(clientWith(adapter));
    await expectLater(
      auth.submitPassword(
        userName: 'abc123',
        password: 'wrong',
        lcid: 1033,
      ),
      throwsA(isA<NeptunAuthException>()),
    );
    expect(
      adapter.paths.any((path) => path.contains('Account/Authenticate')),
      isFalse,
    );
  });

  test('MVC OTP then optional JSON upgrade uses fork Authenticate headers',
      () async {
    final urls = <String>[];
    final tokens = <String>[];
    final adapter = ScriptedAdapter((options) {
      final url = options.uri.toString();
      urls.add(url);
      if (url.contains('Account/Authenticate')) {
        expect(options.headers['Accept'], isNull);
        expect(
          options.headers['User-Agent']?.toString(),
          forkAuthenticateUserAgent,
        );
        final map = asAuthBody(options.data);
        tokens.add('${map['token'] ?? ''}');
        return jsonBody(200, {
          'data': {'accessToken': 'jwt-fork'},
        });
      }
      return eltePortalScript()(options);
    });
    final auth = LiveNeptunAuth(clientWith(adapter));
    final first = await auth.submitPassword(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    expect(first.step, NeptunAuthStep.needsOtp);
    expect(auth.jsonTwoFactorPending, isFalse);

    final done = await auth.submitOtp(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
      otp: '654321',
    );
    expect(done.accessToken, 'jwt-fork');
    expect(tokens.single, '654321');
    expect(
      urls.where((path) => path.contains('Account/Authenticate')),
      hasLength(1),
    );
  });

  test('JSON API miss is skipped; MVC Login still reaches OTP', () async {
    final adapter = ScriptedAdapter(eltePortalScript());
    final ticket = await LiveNeptunAuth(clientWith(adapter)).submitPassword(
      userName: 'n4ibzj',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
    expect(ticket.otpChannel, OtpChannel.authenticator);
    expect(
      adapter.paths.any((path) => path.contains('Account/Authenticate')),
      isFalse,
    );
    expect(
      adapter.paths.any((path) => path.contains('Account/Login')),
      isTrue,
    );
  });

  test('portal form helpers read hidden fields and cookies', () {
    final html =
        '<input type="hidden" name="__RequestVerificationToken" value="abc" />'
        '<input name="LoginName" />';
    final fields = extractNamedInputs(html);
    expect(fields['__RequestVerificationToken'], 'abc');
    expect(fields['LoginName'], '');
    expect(htmlLooksLikeOtp('<input id="TOTPCode" name="TOTPCode" />'), isTrue);
    expect(htmlLooksLikeOtp(eltePasswordLoginHtml), isFalse);
    final loginFields = extractLoginFormFields(eltePasswordLoginHtml);
    expect(loginFields['__RequestVerificationToken'], 'login-token');
    expect(loginFields.containsKey('culture'), isFalse);
    expect(loginFields['returnUrl'], isNull);
    expect(encodeFormBody({'LoginName': 'ABC123'}), 'LoginName=ABC123');
    final jar = <String, String>{};
    mergeSetCookie(jar, ['.Potlap.Session=xyz; path=/; httponly']);
    expect(cookieHeader(jar), '.Potlap.Session=xyz');
    mergeSetCookie(jar, [
      '.Potlap.Antiforgery=abc; path=/; httponly, '
          '.AspNetCore.Mvc.CookieTempDataProvider=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/, '
          '.Potlap.Session=folded; path=/',
    ]);
    expect(jar['.Potlap.Antiforgery'], 'abc');
    expect(jar['.Potlap.Session'], 'folded');
    expect(jar.containsKey('.AspNetCore.Mvc.CookieTempDataProvider'), isFalse);
  });

  test('reset clears JSON pending and device cookie after MVC login', () async {
    final adapter = ScriptedAdapter(eltePortalScript());
    final auth = LiveNeptunAuth(clientWith(adapter));
    await auth.submitPassword(
      userName: 'abc',
      password: 'secret',
      lcid: 1033,
    );
    expect(auth.jsonTwoFactorPending, isFalse);

    auth.reset();
    expect(auth.jsonTwoFactorPending, isFalse);
    expect(auth.deviceCookieValue, isNull);
  });

  test('JWT upgrade after MVC OTP never sends stale Bearer', () async {
    final adapter = ScriptedAdapter((options) {
      if (options.uri.toString().contains('Account/Authenticate')) {
        expect(options.headers['Authorization'], isNull);
        expect(options.headers['X-Requested-With'], isNull);
        expect(options.headers['Origin'], isNull);
        expect(options.headers['Referer'], isNull);
        expect(options.headers['Accept'], isNull);
        expect(
          options.headers['User-Agent']?.toString(),
          forkAuthenticateUserAgent,
        );
        expect(
          options.headers[Headers.contentTypeHeader],
          Headers.jsonContentType,
        );
        return jsonBody(200, {
          'data': {'accessToken': 'jwt'},
        });
      }
      return eltePortalScript()(options);
    });
    final client = clientWith(adapter)..setAccessToken('stale-jwt');
    final auth = LiveNeptunAuth(client);
    await auth.submitPassword(userName: 'a', password: 'b', lcid: 1038);
    final done = await auth.submitOtp(
      userName: 'a',
      password: 'b',
      lcid: 1038,
      otp: '654321',
    );
    expect(done.accessToken, 'jwt');
  });

  test('wrong MVC Authenticator code is OTP reject, not can\'t reach', () async {
    final adapter = ScriptedAdapter(eltePortalScript());
    final auth = LiveNeptunAuth(clientWith(adapter));
    await auth.submitPassword(userName: 'a', password: 'b', lcid: 1038);
    await expectLater(
      auth.submitOtp(
        userName: 'a',
        password: 'b',
        lcid: 1038,
        otp: '11111',
      ),
      throwsA(isA<NeptunOtpException>()),
    );
  });
}
