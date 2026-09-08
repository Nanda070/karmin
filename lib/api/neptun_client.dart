import 'package:dio/dio.dart';

import 'package:karmin/api/dtos/json_util.dart';
import 'package:karmin/api/exceptions.dart';

/// Thin Dio client for ELTE's fork-aligned JSON API.
///
/// Base matches [zoligamer/Neptun-Mobile-fork] institute URL
/// `https://neptun.elte.hu/Account` + `/api/…` — **not** the dead public
/// `ujhallgato/api` stub (404 / empty 400).
///
/// JWT is process memory only — never persisted.
/// On 401 the interceptor drops a **real** JWT and notifies the session. It
/// does **not** retry the original request (OTP must succeed first).
class NeptunClient {
  NeptunClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                // Do not default Content-Type: application/json. GET
                // `/Account/Login` plus a null content-type header makes Dio 5
                // throw ArgumentError, which the login UI mapped to "Can't reach
                // Neptun." JSON POSTs still get application/json from Map bodies.
                headers: const {
                  'User-Agent': userAgent,
                  'Accept': 'application/json, text/plain, */*',
                  'X-Requested-With': 'XMLHttpRequest',
                },
                validateStatus: (status) =>
                    status != null && status >= 200 && status < 300,
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          applyEltePortalBrowserHeaders(options);
          // Never send the MVC placeholder as Bearer — it 401s every GET and
          // falsely triggers the OTP unlock loop.
          if (hasRealJwt) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final path = error.requestOptions.path;
          final isAuth = path.contains('Account/Authenticate');
          if (error.response?.statusCode == 401 &&
              !isAuth &&
              hasRealJwt) {
            clearSession();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Same host as fork Authenticate / calendar / messages.
  static const String baseUrl = 'https://neptun.elte.hu/Account/api/';

  /// Legacy SDA path — public ELTE does not serve student JSON here.
  static const String legacyUjhallgatoBaseUrl =
      'https://neptun.elte.hu/ujhallgato/api/';

  /// MVC cookie login placeholder — not a real Bearer JWT.
  static const String portalSessionToken = 'elte-portal-session';

  static const String userAgent =
      'Karmin/0.1.0 (Flutter; ELTE student client)';

  /// MVC `/Account/Login` is a browser form. A custom UA / XHR header 403s some
  /// Potlap fronts; Safari-like headers match the official iPhone web login.
  static const String portalUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1';

  final Dio _dio;

  /// JWT kept in process memory only — never persisted.
  String? _accessToken;

  /// Called after a 401 on a non-authenticate request. Must not log secrets.
  void Function()? onUnauthorized;

  Dio get dio => _dio;

  String? get accessToken => _accessToken;

  /// Any non-empty RAM token (includes MVC [portalSessionToken]).
  bool get hasJwt => _accessToken != null && _accessToken!.isNotEmpty;

  /// Real JSON Authenticate JWT suitable for `Authorization: Bearer`.
  bool get hasRealJwt =>
      hasJwt && _accessToken != portalSessionToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  void clearSession() {
    _accessToken = null;
  }

  /// GET and unwrap `{ data: ... }` envelopes. Never logs secrets.
  Future<dynamic> getData(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    if (!hasRealJwt) {
      throw const NeptunPortalSessionException();
    }
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: query,
      );
      return unwrap(response.data);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  /// POST and unwrap `{ data: ... }`. Uses Neptun's text when present.
  Future<dynamic> postData(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    if (!hasRealJwt) {
      throw const NeptunPortalSessionException();
    }
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      return unwrap(response.data);
    } on DioException catch (error) {
      throw mapDioException(error, preferApiMessage: true);
    }
  }

  static dynamic unwrap(dynamic raw) {
    if (raw is Map) {
      final nested = raw['data'];
      if (nested != null) {
        return nested;
      }
    }
    return raw;
  }

  /// Maps [lcid] for Neptun: EN → 1033, HU → 1038.
  /// Russian UI keeps 1033 or 1038 (Neptun has no RU lcid).
  static int lcidForLanguageCode(String languageCode) {
    return switch (languageCode) {
      'hu' => 1038,
      _ => 1033,
    };
  }
}

/// True when there was no HTTP response (timeout, DNS, TLS, reset).
bool isDioTransportFailure(DioException error) {
  if (error.response != null) {
    return false;
  }
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout ||
    DioExceptionType.connectionError ||
    DioExceptionType.badCertificate ||
    DioExceptionType.unknown =>
      true,
    DioExceptionType.cancel ||
    DioExceptionType.badResponse =>
      false,
  };
}

/// MVC login is `https://neptun.elte.hu/Account/Login`, not JSON `/Account/api/…`.
bool isEltePortalUri(Uri uri) {
  if (uri.host != 'neptun.elte.hu') {
    return false;
  }
  final path = uri.path.toLowerCase();
  if (path.contains('/ujhallgato/')) {
    return false;
  }
  // Keep JSON Account API on the app User-Agent / XHR defaults (fork-like).
  if (path.contains('/api/')) {
    return false;
  }
  return true;
}

/// True when ELTE returned an HTML shell (maintenance / login page) instead of JSON.
bool looksLikeHtmlPayload(dynamic data) {
  if (data is! String) {
    return false;
  }
  final lower = data.toLowerCase();
  return lower.contains('<html') ||
      lower.contains('<!doctype') ||
      lower.contains('maintenance') ||
      lower.contains('karbantartás') ||
      lower.contains('karbantartas');
}

/// Safari-like GET/POST for the ASP.NET form. Call after Dio composes options
/// so JSON `Content-Type` / XHR defaults are actually removed.
void applyEltePortalBrowserHeaders(RequestOptions options) {
  if (!isEltePortalUri(options.uri)) {
    return;
  }
  options.headers['User-Agent'] = NeptunClient.portalUserAgent;
  options.headers.remove('X-Requested-With');
  if (options.method.toUpperCase() == 'GET') {
    options.headers.remove(Headers.contentTypeHeader);
  }
}

/// Typed mapping for Dio failures. Do not pass request bodies into logs.
/// HTTP from ELTE (any status) is never [NeptunNetworkException].
NeptunException mapDioException(
  DioException error, {
  bool treatingAsOtp = false,
  bool preferApiMessage = false,
}) {
  if (isDioTransportFailure(error)) {
    return const NeptunNetworkException();
  }

  final status = error.response?.statusCode;
  final data = error.response?.data;
  if (looksLikeHtmlPayload(data)) {
    return const NeptunMaintenanceException();
  }
  if (status == 401) {
    return const NeptunSessionExpiredException();
  }
  if (status == 403) {
    return const NeptunForbiddenException();
  }
  if (preferApiMessage) {
    final extracted = extractNeptunMessage(data);
    if (extracted != null) {
      return NeptunApiException(extracted, statusCode: status);
    }
  }
  if (status == 400) {
    return treatingAsOtp
        ? const NeptunOtpException()
        : const NeptunAuthException();
  }
  if (status == 429) {
    return const NeptunLockoutException();
  }
  if (status == 404 || status == 405) {
    return NeptunApiException(
      'Neptun student API path missing.',
      statusCode: status,
    );
  }
  final extracted = extractNeptunMessage(data);
  if (extracted != null) {
    return NeptunApiException(extracted, statusCode: status);
  }
  return NeptunApiException(
    'Neptun request failed.',
    statusCode: status,
  );
}
