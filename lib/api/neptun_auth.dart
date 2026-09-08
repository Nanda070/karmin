import 'dart:convert';

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

  /// Drops JSON 2FA pending + portal cookies. Call on sign-out / account switch.
  void reset();
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
///
/// When [forOtpSubmit] is true, a second 2FA challenge / 400 / 401 becomes
/// [NeptunOtpException] with HTTP status — never silent remap of maintenance.
AuthTicket parseAuthenticateResponse({
  required int? statusCode,
  required dynamic data,
  bool forOtpSubmit = false,
}) {
  if (statusCode == 429) {
    throw const NeptunLockoutException();
  }

  if (looksLikeHtmlPayload(data)) {
    throw const NeptunMaintenanceException();
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
    if (forOtpSubmit) {
      throw NeptunOtpException.reject(
        statusCode: statusCode,
        neptunMessage: extractNeptunMessage(body) ?? extractNeptunMessage(data),
      );
    }
    return AuthTicket(
      step: NeptunAuthStep.needsOtp,
      otpChannel: otpChannelFromPayload(payload),
      otpPrefix: otpPrefixFromPayload(payload),
    );
  }

  if (forOtpSubmit) {
    // Do not collapse password/HTML/401 into the opaque default OTP string.
    throw NeptunOtpException.reject(
      statusCode: statusCode,
      neptunMessage: extractNeptunMessage(body) ?? extractNeptunMessage(data),
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

/// Fork ELTE always sends `LCID: 1038` on Authenticate (password + token).
const int forkAuthenticateLcid = 1038;

/// Body shape from zoligamer/Neptun-Mobile-fork `InstitutesRequest._tryModernLogin`
/// / `submitTwoFactorCode` — key order preserved for JSON encode.
Map<String, dynamic> authenticateJsonBody({
  required String userName,
  required String password,
  int lcid = forkAuthenticateLcid,
  String? otp,
}) {
  final token = otp?.trim() ?? '';
  return <String, dynamic>{
    'userName': normalizeNeptunCode(userName),
    'password': password,
    'captcha': '',
    'captchaIdentifier': '',
    'token': token,
    'LCID': lcid,
  };
}

/// `Cookie: devicecookie-<base64(UPPER username)>=value` — fork exact.
String? forkDeviceCookieHeader({
  required String userName,
  required String? cookieValue,
}) {
  if (cookieValue == null || cookieValue.isEmpty) {
    return null;
  }
  final b64 = base64.encode(utf8.encode(normalizeNeptunCode(userName)));
  return 'devicecookie-$b64=$cookieValue';
}

/// Parse `devicecookie-…=<value>` from Set-Cookie (fork regex).
String? extractDeviceCookieValue(List<String>? setCookieHeaders) {
  if (setCookieHeaders == null || setCookieHeaders.isEmpty) {
    return null;
  }
  final joined = setCookieHeaders.join(', ');
  final match = RegExp(
    r'devicecookie-[a-zA-Z0-9+/=]+=([a-zA-Z0-9+/=]+)',
  ).firstMatch(joined);
  return match?.group(1);
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

  @override
  void reset() {}
}

/// Live login aligned 1:1 with [zoligamer/Neptun-Mobile-fork] for ELTE:
/// `POST {institute}/api/Account/Authenticate` password then same URL + `token`.
///
/// **No MVC fallback** on password/OTP — mixing channels left OTP without a
/// JSON pending session. Optional email resend still uses [EltePortalLogin].
class LiveNeptunAuth implements NeptunAuthApi {
  LiveNeptunAuth(this._client) : _portal = EltePortalLogin(_client);

  final NeptunClient _client;
  final EltePortalLogin _portal;

  /// Set when password 2FA came from JSON Authenticate (fork path).
  var _jsonTwoFactorPending = false;

  /// Fork `devicecookie-…` value from Authenticate Set-Cookie (RAM only).
  String? _deviceCookieValue;

  /// Fork ELTE: `{instituteBase}/api/Account/Authenticate`.
  static const String forkAuthenticateUrl = NeptunClient.authenticateUrl;

  @visibleForTesting
  bool get jsonTwoFactorPending => _jsonTwoFactorPending;

  @visibleForTesting
  String? get deviceCookieValue => _deviceCookieValue;

  /// Alias for [reset].
  void clear() => reset();

  @override
  void reset() {
    _jsonTwoFactorPending = false;
    _deviceCookieValue = null;
    _portal.clear();
  }

  @override
  Future<AuthTicket> submitPassword({
    required String userName,
    required String password,
    required int lcid,
  }) async {
    final code = normalizeNeptunCode(userName);
    // Fresh password attempt: drop MVC cookies. Keep device cookie + JSON
    // pending across unlock re-login (fork keeps device cookie by username).
    _portal.clear();

    final ticket = await _authenticate(
      authenticateJsonBody(
        userName: code,
        password: password,
        // Fork hardcodes 1038 on Authenticate regardless of UI language.
        lcid: forkAuthenticateLcid,
      ),
      userName: code,
    );
    if (ticket.step == NeptunAuthStep.authenticated) {
      _jsonTwoFactorPending = false;
      return ticket;
    }
    if (ticket.step == NeptunAuthStep.needsOtp) {
      _jsonTwoFactorPending = true;
      // Fork has no email dispatch — 2FA is the authenticator `token` field.
      return const AuthTicket(
        step: NeptunAuthStep.needsOtp,
        otpChannel: OtpChannel.authenticator,
        otpPrefix: '',
      );
    }
    throw const NeptunUnavailableException();
  }

  @override
  Future<AuthTicket> submitOtp({
    required String userName,
    required String password,
    required int lcid,
    required String otp,
  }) async {
    // Fork: authenticator digits in `token` — never email `732-` + tail.
    final digits = otp.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      throw NeptunOtpException.reject(neptunMessage: 'empty code');
    }
    final code = normalizeNeptunCode(userName);

    // Same channel as password: fork Authenticate only (no MVC mix).
    final ticket = await _authenticate(
      authenticateJsonBody(
        userName: code,
        password: password,
        lcid: forkAuthenticateLcid,
        otp: digits,
      ),
      userName: code,
      forOtpSubmit: true,
    );
    if (ticket.step == NeptunAuthStep.authenticated) {
      _jsonTwoFactorPending = false;
      _portal.clear();
      return ticket;
    }
    throw NeptunOtpException.reject(statusCode: 202);
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

  /// Absolute `postUri` — bypasses Dio [NeptunClient.baseUrl] merge entirely.
  Future<AuthTicket> _authenticate(
    Map<String, dynamic> payload, {
    required String userName,
    bool forOtpSubmit = false,
  }) async {
    final uri = Uri.parse(forkAuthenticateUrl);
    final cookie = forkDeviceCookieHeader(
      userName: userName,
      cookieValue: _deviceCookieValue,
    );
    try {
      final response = await _client.dio.postUri<dynamic>(
        uri,
        data: payload,
        options: Options(
          headers: {
            Headers.contentTypeHeader: Headers.jsonContentType,
            'Cookie': ?cookie,
          },
          validateStatus: (status) => status != null && status < 500,
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      _absorbDeviceCookie(response.headers.map['set-cookie']);
      return parseAuthenticateResponse(
        statusCode: response.statusCode,
        data: response.data,
        forOtpSubmit: forOtpSubmit,
      );
    } on DioException catch (error) {
      if (error.response != null) {
        _absorbDeviceCookie(error.response!.headers.map['set-cookie']);
        return parseAuthenticateResponse(
          statusCode: error.response!.statusCode,
          data: error.response!.data,
          forOtpSubmit: forOtpSubmit,
        );
      }
      throw mapDioException(error);
    }
  }

  void _absorbDeviceCookie(List<String>? setCookie) {
    final value = extractDeviceCookieValue(setCookie);
    if (value != null && value.isNotEmpty) {
      _deviceCookieValue = value;
    }
  }
}
