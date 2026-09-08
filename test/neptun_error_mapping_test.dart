import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/api/elte_portal_login.dart';
import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_auth.dart';
import 'package:karmin/api/neptun_client.dart';
import 'package:karmin/auth/auth_models.dart';

import 'neptun_auth_test.dart';

DioException transport(
  DioExceptionType type, {
  Response<dynamic>? response,
}) {
  final request = RequestOptions(path: 'https://neptun.elte.hu/Account/Login');
  return DioException(
    requestOptions: request,
    type: type,
    response: response,
  );
}

Response<dynamic> http(int status, [dynamic data]) {
  final request = RequestOptions(path: 'https://neptun.elte.hu/Account/Login');
  return Response<dynamic>(
    requestOptions: request,
    statusCode: status,
    data: data,
  );
}

void main() {
  group('mapDioException', () {
    test('timeout / DNS / TLS without HTTP is can\'t reach Neptun', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
        DioExceptionType.badCertificate,
        DioExceptionType.transformTimeout,
        DioExceptionType.unknown,
      ]) {
        expect(
          mapDioException(transport(type)),
          isA<NeptunNetworkException>(),
          reason: '$type',
        );
      }
    });

    test('HTTP 400 / 404 / HTML are not can\'t reach', () {
      expect(
        mapDioException(
          transport(
            DioExceptionType.badResponse,
            response: http(400, ''),
          ),
        ),
        isA<NeptunAuthException>(),
      );
      expect(
        mapDioException(
          transport(
            DioExceptionType.badResponse,
            response: http(404, '<!DOCTYPE html><html></html>'),
          ),
        ),
        isA<NeptunMaintenanceException>(),
      );
      expect(
        mapDioException(
          transport(
            DioExceptionType.unknown,
            response: http(200, '<html>login</html>'),
          ),
        ),
        isNot(isA<NeptunNetworkException>()),
      );
    });
  });

  test('JSON default Content-Type does not crash GET /Account/Login', () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: NeptunClient.baseUrl,
        headers: const {
          'User-Agent': NeptunClient.userAgent,
          'Accept': 'application/json, text/plain, */*',
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );
    String? postedCookie;
    String? postedUa;
    Object? postedXhr;
    Object? getContentType;
    dio.httpClientAdapter = ScriptedAdapter(
      eltePortalScript(
        onRequest: (options) {
          final url = options.uri.toString();
          if (options.method == 'GET' && isPasswordLoginUrl(url)) {
            getContentType = options.headers['content-type'] ??
                options.headers['Content-Type'];
          }
          if (options.method == 'POST' && isPasswordLoginUrl(url)) {
            postedCookie = options.headers['Cookie']?.toString();
            postedUa = options.headers['User-Agent']?.toString();
            postedXhr = options.headers['X-Requested-With'];
          }
        },
      ),
    );

    final ticket = await EltePortalLogin(NeptunClient(dio: dio)).submitPassword(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
    expect(ticket.otpChannel, OtpChannel.authenticator);
    expect(getContentType, isNull);
    expect(postedXhr, isNull);
    expect(postedUa, contains('Safari'));
    expect(postedCookie, contains('.Potlap.Session=sess'));
    expect(postedCookie, contains('.Potlap.Antiforgery=af'));
  });

  test('portal HTTP 404 is a server error, not can\'t reach', () async {
    final adapter = ScriptedAdapter((options) {
      if (options.uri.toString().contains('Account/Authenticate')) {
        return jsonBody(400, {});
      }
      return htmlBody(404, '<!DOCTYPE html><html><body>Not found</body></html>');
    });
    await expectLater(
      EltePortalLogin(clientWith(adapter)).submitPassword(
        userName: 'abc123',
        password: 'secret',
        lcid: 1033,
      ),
      throwsA(
        isA<NeptunApiException>().having(
          (error) => error.message,
          'message',
          isNot(contains("Can't reach")),
        ),
      ),
    );
  });

  test('portal login error HTML is invalid credentials, not can\'t reach',
      () async {
    final adapter = ScriptedAdapter((options) {
      if (options.uri.toString().contains('Account/Authenticate')) {
        return jsonBody(400, {});
      }
      if (options.method == 'GET') {
        return htmlBody(200, eltePasswordLoginHtml);
      }
      return htmlBody(
        200,
        '$eltePasswordLoginHtml'
        '<div class="validation-summary-errors">Hibás azonosító</div>',
      );
    });
    await expectLater(
      EltePortalLogin(clientWith(adapter)).submitPassword(
        userName: 'abc123',
        password: 'wrong',
        lcid: 1033,
      ),
      throwsA(isA<NeptunAuthException>()),
    );
  });

  test('portal captcha HTML is captcha, not can\'t reach', () async {
    final adapter = ScriptedAdapter((options) {
      if (options.uri.toString().contains('Account/Authenticate')) {
        return jsonBody(400, {});
      }
      if (options.method == 'GET') {
        return htmlBody(200, eltePasswordLoginHtml);
      }
      return htmlBody(200, '<html><body>captcha required</body></html>');
    });
    await expectLater(
      EltePortalLogin(clientWith(adapter)).submitPassword(
        userName: 'abc123',
        password: 'secret',
        lcid: 1033,
      ),
      throwsA(isA<NeptunCaptchaException>()),
    );
  });
}
