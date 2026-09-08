import 'package:dio/dio.dart';

import 'package:karmin/api/dtos/json_util.dart';
import 'package:karmin/api/exceptions.dart';

/// Thin Dio client for `https://neptun.elte.hu/ujhallgato/api/`.
///
/// JWT is process memory only — never persisted.
/// On 401 the interceptor drops the JWT and notifies the session. It does
/// **not** retry the original request (OTP must succeed first).
class NeptunClient {
  NeptunClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: const {
                  'User-Agent': userAgent,
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
                validateStatus: (status) =>
                    status != null && status >= 200 && status < 300,
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final path = error.requestOptions.path;
          final isAuth = path.contains('Account/Authenticate');
          if (error.response?.statusCode == 401 && !isAuth) {
            clearSession();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static const String baseUrl = 'https://neptun.elte.hu/ujhallgato/api/';
  static const String userAgent =
      'Karmin/0.1.0 (Flutter; ELTE student client)';

  final Dio _dio;

  /// JWT kept in process memory only — never persisted.
  String? _accessToken;

  /// Called after a 401 on a non-authenticate request. Must not log secrets.
  void Function()? onUnauthorized;

  Dio get dio => _dio;

  String? get accessToken => _accessToken;

  bool get hasJwt => _accessToken != null && _accessToken!.isNotEmpty;

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

/// Typed mapping for Dio failures. Do not pass request bodies into logs.
NeptunException mapDioException(
  DioException error, {
  bool treatingAsOtp = false,
  bool preferApiMessage = false,
}) {
  final status = error.response?.statusCode;
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.sendTimeout) {
    return const NeptunNetworkException();
  }
  if (status == 401) {
    return const NeptunSessionExpiredException();
  }
  if (status == 403) {
    return const NeptunForbiddenException();
  }
  if (preferApiMessage) {
    final extracted = extractNeptunMessage(error.response?.data);
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
    return const NeptunApiException(
      'Neptun asked us to slow down.',
      statusCode: 429,
    );
  }
  final extracted = extractNeptunMessage(error.response?.data);
  if (extracted != null) {
    return NeptunApiException(extracted, statusCode: status);
  }
  return NeptunApiException(
    'Neptun request failed.',
    statusCode: status,
  );
}
