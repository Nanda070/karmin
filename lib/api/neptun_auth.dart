import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_client.dart';
import 'package:karmin/auth/auth_models.dart';

/// Password / OTP steps against Neptun. Implementations must never log secrets.
abstract interface class NeptunAuthApi {
  Future<AuthTicket> submitPassword({
    required String userName,
    required String password,
    required int lcid,
  });

  Future<AuthTicket> submitOtp({
    required String userName,
    required String password,
    required int lcid,
    required String otp,
  });

  /// Re-sends an email OTP by repeating the password step. No-op for TOTP.
  Future<AuthTicket> resendEmailCode({
    required String userName,
    required String password,
    required int lcid,
  });
}

bool useDebugAuth({
  bool liveOverride = const bool.fromEnvironment(
    'KARMIN_LIVE_AUTH',
    defaultValue: false,
  ),
  bool debugOverride = const bool.fromEnvironment(
    'KARMIN_DEBUG_AUTH',
    defaultValue: false,
  ),
  bool debugMode = kDebugMode,
}) {
  if (liveOverride) {
    return false;
  }
  if (debugOverride) {
    return true;
  }
  return debugMode;
}

OtpChannel otpChannelFromPayload(Map<String, dynamic> data) {
  final raw = (data['twoFactorType'] ??
          data['twoFactorMethod'] ??
          data['otpChannel'] ??
          data['deliveryType'] ??
          '')
      .toString()
      .toLowerCase();
  if (raw.contains('mail') || raw.contains('email')) {
    return OtpChannel.email;
  }
  if (raw.contains('totp') ||
      raw.contains('auth') ||
      raw.contains('app') ||
      raw.contains('google')) {
    return OtpChannel.authenticator;
  }
  return OtpChannel.unknown;
}

/// Debug / web preview: any non-empty credentials, then any 6-digit OTP.
class DebugNeptunAuth implements NeptunAuthApi {
  @override
  Future<AuthTicket> submitPassword({
    required String userName,
    required String password,
    required int lcid,
  }) async {
    if (userName.trim().isEmpty || password.isEmpty) {
      throw const NeptunAuthException();
    }
    return const AuthTicket(
      step: NeptunAuthStep.needsOtp,
      otpChannel: OtpChannel.unknown,
    );
  }

  @override
  Future<AuthTicket> submitOtp({
    required String userName,
    required String password,
    required int lcid,
    required String otp,
  }) async {
    final code = otp.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const NeptunOtpException();
    }
    return AuthTicket(
      step: NeptunAuthStep.authenticated,
      accessToken: 'debug-jwt',
      neptunCode: userName.trim().toUpperCase(),
    );
  }

  @override
  Future<AuthTicket> resendEmailCode({
    required String userName,
    required String password,
    required int lcid,
  }) {
    return submitPassword(
      userName: userName,
      password: password,
      lcid: lcid,
    );
  }
}

/// Live `POST Account/Authenticate` — password, then OTP in `token`.
class LiveNeptunAuth implements NeptunAuthApi {
  LiveNeptunAuth(this._client);

  final NeptunClient _client;

  @override
  Future<AuthTicket> submitPassword({
    required String userName,
    required String password,
    required int lcid,
  }) {
    return _authenticate({
      'userName': userName,
      'password': password,
      'lcid': lcid,
    });
  }

  @override
  Future<AuthTicket> submitOtp({
    required String userName,
    required String password,
    required int lcid,
    required String otp,
  }) async {
    try {
      return await _authenticate({
        'userName': userName,
        'password': password,
        'lcid': lcid,
        'token': otp.trim(),
      });
    } on NeptunAuthException {
      throw const NeptunOtpException();
    }
  }

  @override
  Future<AuthTicket> resendEmailCode({
    required String userName,
    required String password,
    required int lcid,
  }) {
    return submitPassword(
      userName: userName,
      password: password,
      lcid: lcid,
    );
  }

  Future<AuthTicket> _authenticate(Map<String, dynamic> payload) async {
    try {
      final response = await _client.dio.post<dynamic>(
        'Account/Authenticate',
        data: payload,
      );
      return _parse(response);
    } on DioException catch (error) {
      final raw = error.response?.data;
      if (error.response?.statusCode == 202 && raw is Map<String, dynamic>) {
        final data = _unwrap(raw);
        if (data['isCaptchaRequired'] == true && data['accessToken'] == null) {
          throw const NeptunCaptchaException();
        }
        if (data['isTwoFactorRequired'] == true && data['accessToken'] == null) {
          return AuthTicket(
            step: NeptunAuthStep.needsOtp,
            otpChannel: otpChannelFromPayload(data),
          );
        }
      }
      throw _mapDio(error);
    }
  }

  AuthTicket _parse(Response<dynamic> response) {
    final raw = response.data;
    final body = raw is Map<String, dynamic>
        ? raw
        : const <String, dynamic>{};
    final data = _unwrap(body);

    if (data['isCaptchaRequired'] == true && data['accessToken'] == null) {
      throw const NeptunCaptchaException();
    }

    final token = data['accessToken'] as String?;
    if (token != null && token.isNotEmpty) {
      return AuthTicket(
        step: NeptunAuthStep.authenticated,
        accessToken: token,
        neptunCode: data['neptunCode'] as String?,
      );
    }

    if (data['isTwoFactorRequired'] == true) {
      return AuthTicket(
        step: NeptunAuthStep.needsOtp,
        otpChannel: otpChannelFromPayload(data),
      );
    }

    if (response.statusCode == 400) {
      throw const NeptunAuthException();
    }

    throw NeptunApiException(
      'Unexpected authenticate payload.',
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> body) {
    final nested = body['data'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }
    return body;
  }

  NeptunException _mapDio(DioException error) {
    return mapDioException(error);
  }
}
