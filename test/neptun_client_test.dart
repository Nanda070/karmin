import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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
    final client = clientWith(adapter);
    await expectLater(
      client.getData('Dashboard/GetAverages'),
      throwsA(isA<NeptunForbiddenException>()),
    );
  });

  test('live authenticate 202 without token is needsOtp', () async {
    final adapter = ScriptedAdapter(
      (options) => jsonBody(202, {
        'data': {
          'accessToken': null,
          'isTwoFactorRequired': true,
          'isCaptchaRequired': false,
          'twoFactorType': 'email',
        },
      }),
    );
    final client = clientWith(adapter);
    final auth = LiveNeptunAuth(client);
    final ticket = await auth.submitPassword(
      userName: 'abc',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
    expect(ticket.hasJwt, isFalse);
    expect(ticket.otpChannel, OtpChannel.email);
    expect(client.hasJwt, isFalse);
  });

  test('resend-via-relogin is another password POST, not an OTP token', () async {
    final adapter = ScriptedAdapter((options) {
      expect(options.path.contains('Account/Authenticate'), isTrue);
      expect(options.data, isA<Map>());
      final body = options.data as Map;
      expect(body.containsKey('token'), isFalse);
      return jsonBody(202, {
        'data': {
          'isTwoFactorRequired': true,
          'isCaptchaRequired': false,
        },
      });
    });
    final auth = LiveNeptunAuth(clientWith(adapter));
    final ticket = await auth.resendEmailCode(
      userName: 'abc',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
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
    final api = LiveNeptunStudentApi(clientWith(adapter));
    final events = await api.getCalendarEvents(
      start: DateTime(2026, 9, 8),
      end: DateTime(2026, 9, 14),
    );
    expect(events, hasLength(1));
    expect(events.single.title, 'Analysis II');
  });
}
