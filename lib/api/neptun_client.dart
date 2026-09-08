import 'package:dio/dio.dart';

import 'package:karmin/api/exceptions.dart';

/// Thin Dio client for `https://neptun.elte.hu/ujhallgato/api/`.
///
/// Stage 0: skeleton only — no live auth or feature calls yet.
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
                },
              ),
            );

  static const String baseUrl = 'https://neptun.elte.hu/ujhallgato/api/';
  static const String userAgent =
      'Karmin/0.1.0 (Flutter; ELTE student client)';

  final Dio _dio;

  /// JWT kept in process memory only — never persisted.
  String? _accessToken;

  Dio get dio => _dio;

  String? get accessToken => _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  void clearSession() {
    _accessToken = null;
  }

  /// Maps [lcid] for Neptun: EN → 1033, HU → 1038.
  /// Russian UI keeps 1033 or 1038 (Neptun has no RU lcid).
  static int lcidForLanguageCode(String languageCode) {
    return switch (languageCode) {
      'hu' => 1038,
      _ => 1033,
    };
  }

  /// Stage 1 will POST `Account/Authenticate`.
  Future<Never> authenticate({
    required String userName,
    required String password,
    required int lcid,
  }) async {
    throw const NeptunApiException(
      'authenticate is not implemented until Stage 1.',
    );
  }
}
