import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/api/elte_portal_login.dart';
import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_auth.dart';
import 'package:karmin/api/neptun_client.dart';
import 'package:karmin/api/neptun_student_api.dart';
import 'package:karmin/auth/auth_models.dart';

class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.onFetch);

  final ResponseBody Function(RequestOptions options) onFetch;
  int calls = 0;
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    paths.add(options.path);
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

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

ResponseBody jsonBody(int status, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
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

void main() {
  test('401 drops JWT, notifies session, and does not retry', () async {
    var unauthorized = 0;
    final adapter = ScriptedAdapter(
      (options) => jsonBody(401, {'message': 'unauthorized'}),
    );
    final client = clientWith(adapter);
    client.setAccessToken('ram-jwt');
    client.onUnauthorized = () => unauthorized += 1;

    expect(client.hasJwt, isTrue);
    await expectLater(
      client.getData('Calendar/GetCalendarEvents'),
      throwsA(isA<NeptunSessionExpiredException>()),
    );
    expect(client.hasJwt, isFalse);
    expect(unauthorized, 1);
    expect(adapter.calls, 1);
  });

  test('403 becomes a typed forbidden error', () async {
    final adapter = ScriptedAdapter(
      (options) => jsonBody(403, {'message': 'no'}),
    );
    final client = clientWith(adapter)..setAccessToken('ram-jwt');
    await expectLater(
      client.getData('Dashboard/GetAverages'),
      throwsA(isA<NeptunForbiddenException>()),
    );
  });

  test('portal session placeholder is not sent as Bearer', () async {
    String? authHeader;
    final adapter = ScriptedAdapter((options) {
      authHeader = options.headers['Authorization']?.toString();
      return jsonBody(200, {
        'data': [],
      });
    });
    final client = clientWith(adapter)
      ..setAccessToken(NeptunClient.portalSessionToken);
    expect(client.hasJwt, isTrue);
    expect(client.hasRealJwt, isFalse);
    await expectLater(
      client.getData('Calendar/GetCalendarEvents'),
      throwsA(isA<NeptunPortalSessionException>()),
    );
    expect(authHeader, isNull);
    expect(adapter.calls, 0);
  });

  test('real JWT attaches Authorization and uses Account/api base', () async {
    String? authHeader;
    late Uri called;
    final adapter = ScriptedAdapter((options) {
      authHeader = options.headers['Authorization']?.toString();
      called = options.uri;
      return jsonBody(200, {
        'data': [],
      });
    });
    final client = clientWith(adapter)..setAccessToken('live-jwt');
    await client.getData('Calendar/GetCalendarEvents');
    expect(authHeader, 'Bearer live-jwt');
    expect(called.toString(), contains('/Account/api/Calendar/GetCalendarEvents'));
    expect(NeptunClient.baseUrl, 'https://neptun.elte.hu/Account/api/');
  });

  test('Authenticate URL matches fork institute + /api/Account/Authenticate', () {
    expect(
      NeptunClient.instituteBaseUrl,
      'https://neptun.elte.hu/Account',
    );
    expect(
      NeptunClient.authenticateUrl,
      'https://neptun.elte.hu/Account/api/Account/Authenticate',
    );
    expect(
      LiveNeptunAuth.forkAuthenticateUrl,
      NeptunClient.authenticateUrl,
    );
    // Relative student-style path under Account/api is correct.
    expect(
      NeptunClient.resolveAgainstBase('Account/Authenticate').toString(),
      'https://neptun.elte.hu/Account/api/Account/Authenticate',
    );
    // Wrong fork-style relative under api base would double /api/.
    expect(
      NeptunClient.resolveAgainstBase('api/Account/Authenticate').toString(),
      'https://neptun.elte.hu/Account/api/api/Account/Authenticate',
    );
    expect(
      NeptunClient.authenticateUrl.contains('/api/api/'),
      isFalse,
    );
  });

  test('password + OTP Authenticate use absolute fork URL, bare token, no Bearer',
      () async {
    final urls = <String>[];
    final tokens = <String>[];
    final authHeaders = <String?>[];
    final contentTypes = <String?>[];
    final xhr = <String?>[];
    final adapter = ScriptedAdapter((options) {
      urls.add(options.uri.toString());
      authHeaders.add(options.headers['Authorization']?.toString());
      contentTypes.add(options.headers[Headers.contentTypeHeader]?.toString());
      xhr.add(options.headers['X-Requested-With']?.toString());
      final map = asAuthBody(options.data);
      tokens.add('${map['token'] ?? ''}');
      expect(map['LCID'], 1038);
      if ('${map['token'] ?? ''}'.isEmpty) {
        return jsonBody(202, {
          'data': {'isTwoFactorRequired': true},
        });
      }
      return jsonBody(200, {
        'data': {'accessToken': 'jwt-otp'},
      });
    });
    final client = clientWith(adapter)..setAccessToken('stale-jwt');
    final auth = LiveNeptunAuth(client);
    final first = await auth.submitPassword(
      userName: 'abc123',
      password: 'secret',
      lcid: 1038,
    );
    expect(first.step, NeptunAuthStep.needsOtp);
    expect(auth.jsonTwoFactorPending, isTrue);

    final done = await auth.submitOtp(
      userName: 'abc123',
      password: 'secret',
      lcid: 1038,
      otp: '654321',
    );
    expect(done.accessToken, 'jwt-otp');
    expect(urls, hasLength(2));
    expect(
      urls,
      everyElement(
        'https://neptun.elte.hu/Account/api/Account/Authenticate',
      ),
    );
    expect(urls.any((u) => u.contains('/api/api/')), isFalse);
    expect(tokens, ['', '654321']);
    // Stale JWT must not ride along on Authenticate.
    expect(authHeaders, everyElement(isNull));
    expect(xhr, everyElement(isNull));
    expect(contentTypes, everyElement(Headers.jsonContentType));
  });

  test('HTML maintenance body maps to NeptunMaintenanceException', () {
    final error = DioException(
      requestOptions: RequestOptions(
        path: 'Calendar/GetCalendarEvents',
        baseUrl: NeptunClient.baseUrl,
      ),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: 'Calendar/GetCalendarEvents'),
        statusCode: 503,
        data: '<!DOCTYPE html><html><body>Maintenance</body></html>',
      ),
    );
    expect(mapDioException(error), isA<NeptunMaintenanceException>());
  });

  test('portal placeholder 401 does not clear session or notify', () async {
    var unauthorized = 0;
    final adapter = ScriptedAdapter(
      (options) => jsonBody(401, {'message': 'unauthorized'}),
    );
    final client = clientWith(adapter)
      ..setAccessToken(NeptunClient.portalSessionToken)
      ..onUnauthorized = () => unauthorized += 1;

    // Guard throws before HTTP — no 401 path.
    await expectLater(
      client.getData('Calendar/GetCalendarEvents'),
      throwsA(isA<NeptunPortalSessionException>()),
    );
    expect(client.hasJwt, isTrue);
    expect(unauthorized, 0);
  });

  test('live authenticate 202 2FA stays on JSON authenticator (no MVC)', () async {
    var loginPosts = 0;
    final adapter = ScriptedAdapter((options) {
      final url = options.uri.toString();
      if (url.contains('Account/Authenticate')) {
        return jsonBody(202, {
          'data': {
            'accessToken': null,
            'isTwoFactorRequired': true,
            'isCaptchaRequired': false,
            'twoFactorType': 'email',
          },
        });
      }
      if (options.method == 'POST' &&
          url.contains('Account/Login') &&
          !url.contains('Login2FA')) {
        loginPosts += 1;
      }
      if (url.contains('Account/Login')) {
        fail('fork JSON 2FA must not fall through to MVC');
      }
      fail('unexpected ${options.method} $url');
    });
    final client = clientWith(adapter);
    final auth = LiveNeptunAuth(client);
    final ticket = await auth.submitPassword(
      userName: 'abc',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
    expect(ticket.hasJwt, isFalse);
    expect(ticket.otpChannel, OtpChannel.authenticator);
    expect(normalizeOtpPrefix(ticket.otpPrefix), isEmpty);
    expect(client.hasJwt, isFalse);
    expect(loginPosts, 0);
  });

  test('resend-via-relogin POSTs /Account/Login, not JSON Authenticate', () async {
    var loginPosts = 0;
    var authenticatePosts = 0;
    final adapter = ScriptedAdapter((options) {
      final url = options.path.contains('http')
          ? options.uri.toString()
          : options.uri.toString();
      if (url.contains('Account/Authenticate')) {
        authenticatePosts += 1;
        return jsonBody(400, {});
      }
      if (options.method == 'POST' &&
          url.contains('Account/Login') &&
          !url.contains('Login2FA')) {
        loginPosts += 1;
        final data = options.data;
        if (data is Map) {
          expect(data.containsKey('token'), isFalse);
        } else if (data is String) {
          expect(data.contains('token='), isFalse);
        }
        return ResponseBody.fromString(
          '',
          302,
          headers: {
            Headers.contentTypeHeader: ['text/html; charset=utf-8'],
            'location': ['/Account/Login2FA'],
          },
        );
      }
      if (options.method == 'GET' && url.contains('Login2FA')) {
        return ResponseBody.fromString(
          '<form action="/Account/Login2FA" method="post">'
          '<input name="__RequestVerificationToken" value="t" />'
          '<span>732-</span>'
          '<input name="TOTPCode" value="" /></form>',
          200,
          headers: {
            Headers.contentTypeHeader: ['text/html; charset=utf-8'],
          },
        );
      }
      if (options.method == 'POST' && url.contains('Login2FA')) {
        return ResponseBody.fromString(
          '<form action="/Account/Login2FA" method="post">'
          '<input name="__RequestVerificationToken" value="t" />'
          '<span>732-</span>'
          '<input name="TOTPCode" value="" /></form>',
          200,
          headers: {
            Headers.contentTypeHeader: ['text/html; charset=utf-8'],
          },
        );
      }
      if (options.method == 'GET' && url.contains('Account/Login')) {
        return ResponseBody.fromString(
          '<form action="/Account/Login" method="post">'
          '<input name="__RequestVerificationToken" value="tok" />'
          '<input name="LoginName" value="" />'
          '<input name="Password" value="" /></form>',
          200,
          headers: {
            Headers.contentTypeHeader: ['text/html; charset=utf-8'],
          },
        );
      }
      fail('unexpected ${options.method} $url');
    });
    final auth = LiveNeptunAuth(clientWith(adapter));
    final ticket = await auth.resendEmailCode(
      userName: 'abc',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
    expect(loginPosts, 1);
    expect(authenticatePosts, 0);
  });

  test('live student API maps calendar GET', () async {
    final adapter = ScriptedAdapter((options) {
      expect(options.path.contains('Calendar/GetCalendarEvents'), isTrue);
      return jsonBody(200, {
        'data': [
          {
            'title': 'Analysis II',
            'startDate': '2026-09-08T08:00:00.000',
            'endDate': '2026-09-08T10:00:00.000',
            'rooms': 'D 3-510',
            'eventType': 'class',
          },
        ],
      });
    });
    final api = LiveNeptunStudentApi(clientWith(adapter)..setAccessToken('jwt'));
    final events = await api.getCalendarEvents(
      start: DateTime(2026, 9, 8),
      end: DateTime(2026, 9, 14),
    );
    expect(events, hasLength(1));
    expect(events.single.title, 'Analysis II');
  });

  test('exam signup POST uses examId and surfaces Neptun text', () async {
    final adapter = ScriptedAdapter((options) {
      expect(options.path.contains('ExamRegistration/SignUpForExam'), isTrue);
      expect(options.data, {'examId': 'ex-1'});
      return jsonBody(400, {
        'notification': {'message': 'Exam is full'},
      });
    });
    final api = LiveNeptunStudentApi(clientWith(adapter)..setAccessToken('jwt'));
    await expectLater(
      api.signUpForExam('ex-1'),
      throwsA(
        isA<NeptunApiException>().having(
          (error) => error.message,
          'message',
          'Exam is full',
        ),
      ),
    );
  });
}
