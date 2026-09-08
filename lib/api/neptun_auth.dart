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
  // Matches zoligamer/Neptun-Mobile-fork `InstitutesRequest._tryModernLogin` /
  // `submitTwoFactorCode` (lib/API/api_coms.dart) byte-for-byte intent.
  final body = <String, dynamic>{
    'userName': normalizeNeptunCode(userName),
    'password': password,
    'captcha': '',
    'captchaIdentifier': '',
    'token': '',
    'LCID': lcid,
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
      otpChannel: OtpChannel.authenticator,
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

/// Live login aligned with [zoligamer/Neptun-Mobile-fork]:
/// `POST {origin}/Account/api/Account/Authenticate` then 2FA via `token`.
/// MVC `/Account/Login` is only a fallback; email send is never a hard blocker.
class LiveNeptunAuth implements NeptunAuthApi {
  LiveNeptunAuth(this._client) : _portal = EltePortalLogin(_client);

  final NeptunClient _client;
  final EltePortalLogin _portal;

  /// Set when password 2FA came from JSON Authenticate (fork path).
  var _jsonTwoFactorPending = false;

  /// Fork ELTE institute URL → Authenticate under `/Account/api/…`.
  static const String forkAuthenticateUrl =
      '${EltePortalLogin.origin}/Account/api/Account/Authenticate';

  static const _authHeaders = {
    'Content-Type': 'application/json',
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
    _jsonTwoFactorPending = false;

    // 1) Fork modern JSON (primary).
    try {
      final ticket = await _authenticateAbsolute(
        forkAuthenticateUrl,
        authenticateJsonBody(
          userName: code,
          password: password,
          lcid: lcid,
        ),
      );
      if (ticket.step == NeptunAuthStep.authenticated) {
        return ticket;
      }
      if (ticket.step == NeptunAuthStep.needsOtp) {
        // Fork has no email dispatch — 2FA is the authenticator `token` field.
        _jsonTwoFactorPending = true;
        return const AuthTicket(
          step: NeptunAuthStep.needsOtp,
          otpChannel: OtpChannel.authenticator,
          otpPrefix: '',
        );
      }
    } on NeptunCaptchaException {
      rethrow;
    } on NeptunLockoutException {
      rethrow;
    } on NeptunAuthException {
      rethrow;
    } on NeptunException {
      // Fall through to ujhallgato stub / MVC.
    }

    // 2) Legacy Dio base (`ujhallgato/api`) — usually empty 400 on public ELTE.
    try {
      final ticket = await _authenticateRelative(
        authenticateJsonBody(
          userName: code,
          password: password,
          lcid: lcid,
        ),
      );
      if (ticket.step == NeptunAuthStep.authenticated) {
        return ticket;
      }
      if (ticket.step == NeptunAuthStep.needsOtp) {
        _jsonTwoFactorPending = true;
        return const AuthTicket(
          step: NeptunAuthStep.needsOtp,
          otpChannel: OtpChannel.authenticator,
          otpPrefix: '',
        );
      }
    } on NeptunCaptchaException {
      rethrow;
    } on NeptunLockoutException {
      rethrow;
    } on NeptunAuthException {
      rethrow;
    } on NeptunException {
      // MVC fallback.
    }

    // 3) ASP.NET MVC Login2FA — prefer authenticator; email is optional (resend).
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
    // Fork: bare authenticator digits in `token` — never email `732-` + tail.
    final digits = otp.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      throw const NeptunOtpException();
    }
    final token = digits;

    final preferJson = _jsonTwoFactorPending || !_portal.hasSession;
    if (preferJson) {
      final payload = authenticateJsonBody(
        userName: userName,
        password: password,
        lcid: lcid,
        otp: token,
      );
      try {
        final ticket =
            await _authenticateAbsolute(forkAuthenticateUrl, payload);
        if (ticket.step == NeptunAuthStep.authenticated) {
          _jsonTwoFactorPending = false;
        }
        return ticket;
      } on NeptunOtpException {
        rethrow;
      } on NeptunAuthException {
        throw const NeptunOtpException();
      } on NeptunUnavailableException {
        // try relative / portal
      } on NeptunException {
        // try relative / portal
      }

      try {
        final ticket = await _authenticateRelative(payload);
        if (ticket.step == NeptunAuthStep.authenticated) {
          _jsonTwoFactorPending = false;
        }
        return ticket;
      } on NeptunAuthException {
        // Give MVC portal a chance when a Login2FA session exists.
      } on NeptunUnavailableException {
        // Give MVC portal a chance when a Login2FA session exists.
      } on NeptunOtpException {
        if (!_portal.hasSession) {
          rethrow;
        }
      }
    }

    if (_portal.hasSession) {
      return _portal.submitOtp(otp: token);
    }
    throw const NeptunOtpException();
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

  Future<AuthTicket> _authenticateAbsolute(
    String url,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _client.dio.post<dynamic>(
        url,
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

  Future<AuthTicket> _authenticateRelative(Map<String, dynamic> payload) async {
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
