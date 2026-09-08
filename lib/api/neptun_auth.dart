import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:karmin/api/dtos/json_util.dart';
import 'package:karmin/api/elte_portal_login.dart';
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

/// Trim + uppercase. Neptun codes are 6-char alphanumeric; web login is
/// case-insensitive but the JSON API is not always.
String normalizeNeptunCode(String raw) => raw.trim().toUpperCase();

OtpChannel otpChannelFromPayload(Map<String, dynamic> data) {
  final raw = (firstValue(data, const [
            'twoFactorType',
            'twoFactorMethod',
            'otpChannel',
            'deliveryType',
            'TwoFactorType',
          ]) ??
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

Map<String, dynamic> unwrapAuthData(Map<String, dynamic> body) {
  final nested = body['data'] ?? body['Data'];
  if (nested is Map) {
    return stringKeyed(nested);
  }
  return body;
}

bool isCaptchaRequired(Map<String, dynamic> data) {
  return asBool(
    firstValue(data, const [
      'isCaptchaRequired',
      'IsCaptchaRequired',
      'captchaRequired',
      'needCaptcha',
      'needsCaptcha',
    ]),
  );
}

bool isTwoFactorRequired(Map<String, dynamic> data) {
  if (asBool(
    firstValue(data, const [
      'isTwoFactorRequired',
      'IsTwoFactorRequired',
      'twoFactorRequired',
      'needTwoFactor',
      'needsTwoFactor',
      'requiresTwoFactor',
      'twoFactor',
      'isTwoFactor',
    ]),
  )) {
    return true;
  }
  final type = asNonEmptyString(
    firstValue(data, const [
      'twoFactorType',
      'twoFactorMethod',
      'otpChannel',
      'deliveryType',
    ]),
  );
  return type != null;
}

bool looksLikeMissingAuthApi(int? status, dynamic raw) {
  if (status == 404 || status == 405 || status == 409) {
    return true;
  }
  if (raw == null) {
    return status == 400 || status == 401;
  }
  if (raw is String) {
    final text = raw.trim();
    if (text.isEmpty) {
      return status == 400 || status == 401;
    }
    final lower = text.toLowerCase();
    if (lower.contains('<html') || lower.contains('<!doctype')) {
      return true;
    }
  }
  if (raw is Map && raw.isEmpty) {
    return status == 400;
  }
  return false;
}

/// Maps an Authenticate HTTP result. HTTP 202 without a JWT is OTP, never
/// invalid credentials. Does not log the body (may contain tokens).
AuthTicket parseAuthenticateResponse({
  required int? statusCode,
  required dynamic data,
}) {
  if (statusCode == 429) {
    throw const NeptunLockoutException();
  }

  final body = asJsonMap(data);
  final payload = unwrapAuthData(body);
  final accessToken = asNonEmptyString(
    firstValue(payload, const [
      'accessToken',
      'AccessToken',
      'jwt',
      'access_token',
    ]),
  );

  if (isCaptchaRequired(payload) && accessToken == null) {
    throw const NeptunCaptchaException();
  }

  if (accessToken != null) {
    return AuthTicket(
      step: NeptunAuthStep.authenticated,
      accessToken: accessToken,
      neptunCode: asNonEmptyString(
        firstValue(payload, const ['neptunCode', 'NeptunCode', 'userName']),
      ),
    );
  }

  final twoFactor = isTwoFactorRequired(payload) ||
      statusCode == 202 ||
      looksLikeTwoFactorMessage(body, data);

  if (twoFactor) {
    return AuthTicket(
      step: NeptunAuthStep.needsOtp,
      otpChannel: otpChannelFromPayload(payload),
      otpPrefix: otpPrefixFromPayload(payload),
    );
  }

  if (looksLikeMissingAuthApi(statusCode, data)) {
    throw const NeptunUnavailableException();
  }

  if (statusCode == 400 || statusCode == 401) {
    throw const NeptunAuthException();
  }
  if (statusCode == 403) {
    throw const NeptunForbiddenException();
  }
  if (statusCode != null && statusCode >= 500) {
    throw NeptunApiException(
      'Neptun request failed.',
      statusCode: statusCode,
    );
  }

  throw NeptunApiException(
    'Unexpected authenticate payload.',
    statusCode: statusCode,
  );
}

bool looksLikeTwoFactorMessage(Map<String, dynamic> body, dynamic raw) {
  final extracted = extractNeptunMessage(body) ?? extractNeptunMessage(raw);
  if (extracted == null) {
    return false;
  }
  final lower = extracted.toLowerCase();
  return lower.contains('two-factor') ||
      lower.contains('two factor') ||
      lower.contains('2fa') ||
      lower.contains('kétlépcsős') ||
      lower.contains('ketlepcsos') ||
      lower.contains('egyszeri') ||
      lower.contains('authenticator');
}

Map<String, dynamic> authenticateJsonBody({
  required String userName,
  required String password,
  required int lcid,
  String? otp,
}) {
  final body = <String, dynamic>{
    'userName': normalizeNeptunCode(userName),
    'password': password,
    'lcid': lcid,
    'captcha': '',
  };
  final token = otp?.trim();
  if (token != null && token.isNotEmpty) {
    body['token'] = token;
  }
  return body;
}

/// Debug / web preview: any non-empty credentials, then a 6–16 digit OTP.
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
      otpChannel: OtpChannel.email,
    );
  }

  @override
  Future<AuthTicket> submitOtp({
    required String userName,
    required String password,
    required int lcid,
    required String otp,
  }) async {
    final digits = otp.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6 || digits.length > 16) {
      throw const NeptunOtpException();
    }
    return AuthTicket(
      step: NeptunAuthStep.authenticated,
      accessToken: 'debug-jwt',
      neptunCode: normalizeNeptunCode(userName),
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

/// Live login: JSON `POST Account/Authenticate` (SDA student web), then ELTE
/// MVC `/Account/Login` if that JSON API is missing.
class LiveNeptunAuth implements NeptunAuthApi {
  LiveNeptunAuth(this._client) : _portal = EltePortalLogin(_client);

  final NeptunClient _client;
  final EltePortalLogin _portal;

  static const _authHeaders = {
    'X-Requested-With': 'XMLHttpRequest',
    'Accept': 'application/json, text/plain, */*',
    'Origin': EltePortalLogin.origin,
    'Referer': '${EltePortalLogin.origin}/Account/Login',
  };

  @override
  Future<AuthTicket> submitPassword({
    required String userName,
    required String password,
    required int lcid,
  }) async {
    final code = normalizeNeptunCode(userName);
    _portal.clear();
    try {
      final ticket = await _authenticate(
        authenticateJsonBody(
          userName: code,
          password: password,
          lcid: lcid,
        ),
      );
      if (ticket.step == NeptunAuthStep.authenticated) {
        return ticket;
      }
      // JSON 2FA does not dispatch ELTE email. MVC POST /Account/Login does.
    } on NeptunCaptchaException {
      rethrow;
    } on NeptunLockoutException {
      rethrow;
    } on NeptunAuthException {
      rethrow;
    } on NeptunException {
      // JSON `/ujhallgato/api` is a 400/404 stub and often hangs; MVC login
      // on the host root is the real ELTE path.
    }
    return _portal.submitPassword(
      userName: code,
      password: password,
      lcid: lcid,
    );
  }

  @override
  Future<AuthTicket> submitOtp({
    required String userName,
    required String password,
    required int lcid,
    required String otp,
  }) async {
    if (_portal.hasSession) {
      return _portal.submitOtp(otp: otp);
    }
    try {
      return await _authenticate(
        authenticateJsonBody(
          userName: userName,
          password: password,
          lcid: lcid,
          otp: otp,
        ),
      );
    } on NeptunAuthException {
      throw const NeptunOtpException();
    } on NeptunUnavailableException {
      throw const NeptunOtpException();
    }
  }

  @override
  Future<AuthTicket> resendEmailCode({
    required String userName,
    required String password,
    required int lcid,
  }) {
    return _portal.resendEmailCode(
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
        options: Options(
          headers: _authHeaders,
          validateStatus: (status) => status != null && status < 500,
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      return parseAuthenticateResponse(
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (error) {
      if (error.response != null) {
        return parseAuthenticateResponse(
          statusCode: error.response!.statusCode,
          data: error.response!.data,
        );
      }
      throw mapDioException(error);
    }
  }
}
