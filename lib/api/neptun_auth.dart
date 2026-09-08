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
    throw NeptunMaintenanceException.detail(statusCode: statusCode);
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
      neptunMessage: extractNeptunMessage(body) ??
          extractNeptunMessage(data) ??
          emptyAuthenticateBodySnippet(data),
    );
  }

  final snippet = extractNeptunMessage(body) ??
      extractNeptunMessage(data) ??
      emptyAuthenticateBodySnippet(data);

  if (looksLikeMissingAuthApi(statusCode, data)) {
    throw NeptunUnavailableException.detail(
      statusCode: statusCode,
      neptunMessage: snippet,
    );
  }

  if (statusCode == 400 || statusCode == 401) {
    if (looksLikeInvalidCredentialsMessage(snippet)) {
      throw NeptunAuthException.reject(
        statusCode: statusCode,
        neptunMessage: snippet,
      );
    }
    // Generic ASP.NET 400 (missing JSON API / empty body) is not a
    // bad password — password probe may fall through to MVC Login.
    throw NeptunUnavailableException.detail(
      statusCode: statusCode,
      neptunMessage: snippet,
    );
  }
  if (statusCode == 403) {
    throw const NeptunForbiddenException();
  }
  if (statusCode != null && statusCode >= 500) {
    throw NeptunApiException(
      formatNeptunStatusMessage(
        fallback: 'Neptun request failed',
        statusCode: statusCode,
        neptunMessage: snippet,
      ),
      statusCode: statusCode,
    );
  }

  throw NeptunApiException(
    formatNeptunStatusMessage(
      fallback: 'Unexpected authenticate payload',
      statusCode: statusCode,
      neptunMessage: snippet,
    ),
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

/// Fork ELTE body uses `LCID: 1038`. English Karmin UI is 1033.
const int forkAuthenticateLcid = 1038;

/// English / default Neptun LCID.
const int englishAuthenticateLcid = 1033;

/// LCID for one JSON Authenticate probe. Russian UI has no Neptun lcid.
int authenticateLcidForUi(int uiLcid) {
  if (uiLcid == 1033 || uiLcid == 1038) {
    return uiLcid;
  }
  return forkAuthenticateLcid;
}

/// Empty / missing Authenticate body — so the UI is never just “HTTP 400”.
String? emptyAuthenticateBodySnippet(dynamic data) {
  if (data == null) {
    return 'empty body';
  }
  if (data is String && data.trim().isEmpty) {
    return 'empty body';
  }
  if (data is Map && data.isEmpty) {
    return 'empty body';
  }
  return null;
}

/// Explicit wrong-password text from Neptun — not a generic ASP.NET 400.
bool looksLikeInvalidCredentialsMessage(String? neptunMessage) {
  if (neptunMessage == null) {
    return false;
  }
  final lower = neptunMessage.toLowerCase();
  if (lower.isEmpty) {
    return false;
  }
  return lower.contains('invalid user') ||
      lower.contains('user name or password') ||
      lower.contains('username or password') ||
      lower.contains('wrong password') ||
      lower.contains('incorrect password') ||
      lower.contains('incorrect user') ||
      lower.contains('hibás azonos') ||
      lower.contains('hibas azonos') ||
      lower.contains('hibás jelszó') ||
      lower.contains('hibas jelszo') ||
      lower.contains('rossz jelszó') ||
      lower.contains('rossz jelszo');
}

/// Bad password / captcha / lockout / network — do not fall through to MVC.
/// Generic HTTP 400 ([NeptunUnavailableException]) is a JSON-API miss.
bool isHardAuthenticateFailure(NeptunException error) {
  return error is NeptunAuthException ||
      error is NeptunCaptchaException ||
      error is NeptunLockoutException ||
      error is NeptunNetworkException ||
      error is NeptunForbiddenException;
}

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

/// Live ELTE login.
///
/// Public `neptun.elte.hu` does **not** host the SDA JSON Authenticate
/// controller (live dummy POST → empty HTTP 400, GET → HTML 404). On
/// iPhone that dead path often times out / resets with **no HTTP
/// status**, which used to map to “Can't reach Neptun” and abort before
/// MVC. Password login is therefore **only** Potlap MVC: GET
/// `/Account/Login` (cookies + antiforgery) then POST `LoginName` /
/// `Password`, then `/Account/Login2FA` with Microsoft Authenticator
/// digits. JSON Authenticate is used only as an optional JWT upgrade
/// after a successful MVC OTP — never on the password step.
class LiveNeptunAuth implements NeptunAuthApi {
  LiveNeptunAuth(this._client) : _portal = EltePortalLogin(_client);

  final NeptunClient _client;
  final EltePortalLogin _portal;

  /// Set when password 2FA came from JSON Authenticate (fork path).
  var _jsonTwoFactorPending = false;

  /// Fork `devicecookie-…` value from Authenticate Set-Cookie (RAM only).
  String? _deviceCookieValue;

  /// LCID that last reached JSON 2FA / JWT. OTP must reuse it.
  int? _authenticateLcid;

  /// Fork ELTE: `{instituteBase}/api/Account/Authenticate`.
  static const String forkAuthenticateUrl = NeptunClient.authenticateUrl;

  @visibleForTesting
  bool get jsonTwoFactorPending => _jsonTwoFactorPending;

  @visibleForTesting
  String? get deviceCookieValue => _deviceCookieValue;

  @visibleForTesting
  int? get lastAuthenticateLcid => _authenticateLcid;

  /// Alias for [reset].
  void clear() => reset();

  @override
  void reset() {
    _jsonTwoFactorPending = false;
    _deviceCookieValue = null;
    _authenticateLcid = null;
    _portal.clear();
  }

  @override
  Future<AuthTicket> submitPassword({
    required String userName,
    required String password,
    required int lcid,
  }) async {
    final code = normalizeNeptunCode(userName);
    // Fresh password attempt: drop MVC cookies. Do **not** POST the dead
    // JSON Authenticate first — timeout there is “Can't reach Neptun”
    // and never opens Verification. Device cookie is only for a later
    // JWT upgrade after MVC OTP.
    _portal.clear();
    _jsonTwoFactorPending = false;
    _authenticateLcid = null;
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
    // Fork: authenticator digits in `token` — never email `732-` + tail.
    final digits = otp.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      throw NeptunOtpException.reject(neptunMessage: 'empty code');
    }
    final code = normalizeNeptunCode(userName);
    final otpLcid = _authenticateLcid ?? authenticateLcidForUi(lcid);

    if (_jsonTwoFactorPending) {
      final ticket = await _authenticate(
        authenticateJsonBody(
          userName: code,
          password: password,
          lcid: otpLcid,
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

    if (_portal.hasSession) {
      final ticket = await _portal.submitOtp(otp: digits);
      if (ticket.step == NeptunAuthStep.authenticated) {
        final upgraded = await _tryJsonJwtAfterPortalOtp(
          userName: code,
          password: password,
          lcid: otpLcid,
          otp: digits,
        );
        return upgraded ?? ticket;
      }
      throw NeptunOtpException.reject(statusCode: 202);
    }

    final ticket = await _authenticate(
      authenticateJsonBody(
        userName: code,
        password: password,
        lcid: otpLcid,
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

  Future<AuthTicket?> _tryJsonJwtAfterPortalOtp({
    required String userName,
    required String password,
    required int lcid,
    required String otp,
  }) async {
    try {
      final ticket = await _authenticate(
        authenticateJsonBody(
          userName: userName,
          password: password,
          lcid: lcid,
          otp: otp,
        ),
        userName: userName,
      );
      if (ticket.step == NeptunAuthStep.authenticated && ticket.hasJwt) {
        _jsonTwoFactorPending = false;
        _portal.clear();
        return ticket;
      }
    } on NeptunException {
      // Public ELTE has no JSON Authenticate — keep the MVC session.
    }
    return null;
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
    // Fork `jsonEncode`s the map itself (`Content-Type: application/json`,
    // no charset). A Dio Map body often becomes `application/json; charset=utf-8`.
    final encoded = jsonEncode(payload);
    try {
      final response = await _client.dio.postUri<dynamic>(
        uri,
        data: encoded,
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            Headers.contentTypeHeader: Headers.jsonContentType,
            'Cookie': ?cookie,
          },
          extra: const {
            authenticateHeaderProfileExtra: 'fork',
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
