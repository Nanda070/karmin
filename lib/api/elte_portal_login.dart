import 'package:dio/dio.dart';

import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_client.dart';
import 'package:karmin/auth/auth_models.dart';

/// ELTE public login is ASP.NET MVC (`LoginName` + `Password` to
/// `/Account/Login`), not the SDA JSON `ujhallgato` API.
///
/// After a valid password the portal sends the user to `/Account/Login2FA`.
class EltePortalLogin {
  EltePortalLogin(this._client);

  static const String origin = 'https://neptun.elte.hu';
  static const String loginPath = '/Account/Login';
  static const String otpPath = '/Account/Login2FA';

  final NeptunClient _client;
  final Map<String, String> _cookies = {};
  Map<String, String> _otpFields = {};
  String _otpPrefix = '';
  var _hasSession = false;

  bool get hasSession => _hasSession;

  void clear() {
    _cookies.clear();
    _otpFields = {};
    _otpPrefix = '';
    _hasSession = false;
  }

  Future<AuthTicket> submitPassword({
    required String userName,
    required String password,
    required int lcid,
  }) async {
    final code = userName.trim().toUpperCase();
    final loginHtml = await _get(loginPath);
    final fields = extractNamedInputs(loginHtml);
    fields['LoginName'] = code;
    fields['Password'] = password;
    fields.putIfAbsent('ReturnUrl', () => '');

    final response = await _post(loginPath, fields, referer: '$origin$loginPath');
    final ticket = _ticketFromPortalResponse(response);
    if (ticket.step != NeptunAuthStep.needsOtp) {
      return ticket;
    }
    var otpHtml = '';
    if (_otpFields.isEmpty || _otpPrefix.isEmpty) {
      try {
        otpHtml = await _get(otpPath);
        _captureOtpForm(otpHtml);
      } on NeptunException {
        // OTP submit will GET Login2FA again with the session cookie.
      }
    }
    return AuthTicket(
      step: NeptunAuthStep.needsOtp,
      otpChannel: otpHtml.isNotEmpty
          ? otpChannelFromHtml(otpHtml, otpPath)
          : ticket.otpChannel,
      otpPrefix: _otpPrefix,
    );
  }

  Future<AuthTicket> submitOtp({
    required String otp,
  }) async {
    var fields = Map<String, String>.from(_otpFields);
    if (fields.isEmpty) {
      final html = await _get(otpPath);
      _captureOtpForm(html);
      fields = Map<String, String>.from(_otpFields);
    }
    fields = fillLogin2FaOtpFields(
      fields: fields,
      prefix: _otpPrefix,
      tail: otp,
    );

    final response = await _post(otpPath, fields, referer: '$origin$otpPath');
    final ticket = _ticketFromPortalResponse(response, treatingAsOtp: true);
    if (ticket.step == NeptunAuthStep.needsOtp) {
      throw const NeptunOtpException();
    }
    return ticket;
  }

  Future<AuthTicket> resendEmailCode({
    required String userName,
    required String password,
    required int lcid,
  }) {
    clear();
    return submitPassword(
      userName: userName,
      password: password,
      lcid: lcid,
    );
  }

  Future<String> _get(String path) async {
    try {
      final response = await _client.dio.get<dynamic>(
        '$origin$path',
        options: _options(referer: '$origin$loginPath'),
      );
      _storeCookies(response);
      return _htmlOf(response);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<Response<dynamic>> _post(
    String path,
    Map<String, String> fields, {
    required String referer,
  }) async {
    try {
      final response = await _client.dio.post<dynamic>(
        '$origin$path',
        data: fields,
        options: _options(
          referer: referer,
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      _storeCookies(response);
      return response;
    } on DioException catch (error) {
      if (error.response != null) {
        _storeCookies(error.response!);
        return error.response!;
      }
      throw mapDioException(error);
    }
  }

  Options _options({
    required String referer,
    String? contentType,
  }) {
    return Options(
      followRedirects: false,
      validateStatus: (status) => status != null && status < 500,
      contentType: contentType,
      headers: {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Origin': origin,
        'Referer': referer,
        if (_cookies.isNotEmpty) 'Cookie': cookieHeader(_cookies),
      },
    );
  }

  AuthTicket _ticketFromPortalResponse(
    Response<dynamic> response, {
    bool treatingAsOtp = false,
  }) {
    final status = response.statusCode ?? 0;
    final location = response.headers.value('location') ?? '';
    final html = _htmlOf(response);

    if (status == 429) {
      throw const NeptunLockoutException();
    }
    if (status == 404 || status == 405) {
      throw const NeptunUnavailableException();
    }

    if (status >= 300 &&
        status < 400 &&
        location.toLowerCase().contains('login') &&
        !location.contains('Login2FA')) {
      if (treatingAsOtp) {
        throw const NeptunOtpException();
      }
      throw const NeptunAuthException();
    }

    if (_isOtpChallenge(status, location, html)) {
      _captureOtpForm(html);
      _hasSession = true;
      return AuthTicket(
        step: NeptunAuthStep.needsOtp,
        otpChannel: otpChannelFromHtml(html, location),
        otpPrefix: _otpPrefix,
      );
    }

    if (_looksLoggedIn(status, location, html)) {
      _hasSession = true;
      return const AuthTicket(
        step: NeptunAuthStep.authenticated,
        accessToken: 'elte-portal-session',
      );
    }

    if (htmlLooksLikeLoginError(html) ||
        status == 400 ||
        status == 401 ||
        html.toLowerCase().contains('loginname')) {
      if (treatingAsOtp) {
        throw const NeptunOtpException();
      }
      throw const NeptunAuthException();
    }

    if (status >= 300 && status < 400 && location.contains('Login2FA')) {
      _hasSession = true;
      return AuthTicket(
        step: NeptunAuthStep.needsOtp,
        otpChannel: otpChannelFromHtml(html, location),
        otpPrefix: _otpPrefix,
      );
    }

    throw const NeptunUnavailableException();
  }

  bool _isOtpChallenge(int status, String location, String html) {
    if (location.contains('Login2FA')) {
      return true;
    }
    return htmlLooksLikeOtp(html);
  }

  bool _looksLoggedIn(int status, String location, String html) {
    final loc = location.toLowerCase();
    if (loc.contains('login')) {
      return false;
    }
    if (status >= 300 && status < 400 && loc.isNotEmpty) {
      return true;
    }
    final lower = html.toLowerCase();
    return lower.contains('hallgatói web') ||
        lower.contains('hallgatoi web') ||
        lower.contains('sign out') ||
        lower.contains('kijelentkezés');
  }

  void _storeCookies(Response<dynamic> response) {
    mergeSetCookie(_cookies, response.headers.map['set-cookie']);
  }

  String _htmlOf(Response<dynamic> response) {
    final data = response.data;
    if (data is String) {
      return data;
    }
    return data?.toString() ?? '';
  }

  void _captureOtpForm(String html) {
    if (html.trim().isEmpty) {
      return;
    }
    final fields = extractNamedInputs(html);
    if (fields.isNotEmpty) {
      _otpFields = fields;
    }
    final prefix = parseLogin2FaPrefix(html);
    if (prefix != null && prefix.isNotEmpty) {
      _otpPrefix = prefix;
    }
  }
}

String cookieHeader(Map<String, String> cookies) {
  return cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');
}

void mergeSetCookie(Map<String, String> jar, List<String>? headers) {
  if (headers == null) {
    return;
  }
  for (final header in headers) {
    final part = header.split(';').first;
    final eq = part.indexOf('=');
    if (eq <= 0) {
      continue;
    }
    final name = part.substring(0, eq).trim();
    final value = part.substring(eq + 1).trim();
    if (name.isEmpty) {
      continue;
    }
    jar[name] = value;
  }
}

Map<String, String> extractNamedInputs(String html) {
  final fields = <String, String>{};
  final input = RegExp(r'<input\b([^>]*)>', caseSensitive: false);
  for (final match in input.allMatches(html)) {
    final attrs = match.group(1) ?? '';
    final name = _attr(attrs, 'name');
    if (name == null || name.isEmpty) {
      continue;
    }
    fields[name] = _attr(attrs, 'value') ?? '';
  }
  return fields;
}

bool htmlLooksLikeOtp(String html) {
  final lower = html.toLowerCase();
  return lower.contains('login2fa') ||
      lower.contains('totpcode') ||
      lower.contains('name="phase"') ||
      lower.contains("name='phase'") ||
      lower.contains('two-factor') ||
      lower.contains('two factor') ||
      lower.contains('e-mail code') ||
      lower.contains('email code') ||
      lower.contains('e-mail kód') ||
      lower.contains('kétlépcsős') ||
      lower.contains('ketlepcsos') ||
      lower.contains('egyszeri') ||
      lower.contains('authenticator') ||
      lower.contains('hitelesítő');
}

bool htmlLooksLikeLoginError(String html) {
  final lower = html.toLowerCase();
  return lower.contains('field-validation-error') ||
      lower.contains('validation-summary-errors') ||
      lower.contains('hibás') ||
      lower.contains('hibas') ||
      lower.contains('invalid') ||
      lower.contains('rejected') ||
      lower.contains('sikertelen');
}

OtpChannel otpChannelFromHtml(String html, String location) {
  final blob = '$html $location'.toLowerCase();
  if (blob.contains('mail') || blob.contains('email') || blob.contains('e-mail')) {
    return OtpChannel.email;
  }
  if (blob.contains('totp') ||
      blob.contains('authenticator') ||
      blob.contains('hitelesítő') ||
      blob.contains('google')) {
    return OtpChannel.authenticator;
  }
  return OtpChannel.unknown;
}

String? _attr(String attrs, String name) {
  final quoted = RegExp(
    '$name\\s*=\\s*"([^"]*)"',
    caseSensitive: false,
  ).firstMatch(attrs);
  if (quoted != null) {
    return quoted.group(1);
  }
  final single = RegExp(
    "$name\\s*=\\s*'([^']*)'",
    caseSensitive: false,
  ).firstMatch(attrs);
  return single?.group(1);
}

const _otpPrefixFieldNames = {
  'prefix',
  'codeprefix',
  'tokenprefix',
  'emailprefix',
  'otpprefix',
  'totpprefix',
  'emailcodeprefix',
  'twofactorprefix',
  'codestart',
  'tokenstart',
};

const _otpCodeFieldNames = {
  'totpcode',
  'code',
  'emailcode',
  'onetimecode',
  'token',
  'twofactorcode',
  'otp',
  'otpcode',
};

final _otpPrefixOnly = RegExp(r'^\d{2,4}-?$');
final _otpStandalonePrefix = RegExp(r'(?<![\d])(\d{3}-)(?!\d)');

bool isOtpPrefixFieldName(String name) =>
    _otpPrefixFieldNames.contains(name.toLowerCase());

bool isOtpCodeFieldName(String name) {
  final lower = name.toLowerCase();
  return _otpCodeFieldNames.contains(lower) && !isOtpPrefixFieldName(name);
}

/// `732-` from `732`, `732-`, or ` 732 - `. Empty when the value is not a prefix.
String? asOtpPrefix(String? raw) {
  if (raw == null) {
    return null;
  }
  final trimmed = raw.trim().replaceAll(' ', '');
  if (!_otpPrefixOnly.hasMatch(trimmed)) {
    return null;
  }
  return '${trimmed.replaceAll(RegExp(r'\D'), '')}-';
}

String normalizeOtpPrefix(String raw) => asOtpPrefix(raw) ?? '';

/// Digits the user typed. Strips a leading copy of [prefix] if they pasted the
/// full email code.
String normalizeOtpTail(String raw, {String prefix = ''}) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  final prefixDigits = prefix.replaceAll(RegExp(r'\D'), '');
  if (prefixDigits.isNotEmpty &&
      digits.startsWith(prefixDigits) &&
      digits.length > prefixDigits.length) {
    digits = digits.substring(prefixDigits.length);
  }
  return digits;
}

/// Official email OTP is prefix + hyphen + tail (`732-893600`). Authenticator
/// codes have no prefix and stay 6 digits.
String composeLogin2FaCode({
  required String prefix,
  required String tail,
}) {
  final normalizedPrefix = normalizeOtpPrefix(prefix);
  final normalizedTail = normalizeOtpTail(tail, prefix: normalizedPrefix);
  if (normalizedPrefix.isEmpty) {
    return normalizedTail;
  }
  return '$normalizedPrefix$normalizedTail';
}

/// Reads the grey-box prefix Neptun already filled on Login2FA.
String? parseLogin2FaPrefix(String html) {
  final fields = extractNamedInputs(html);
  for (final entry in fields.entries) {
    if (isOtpPrefixFieldName(entry.key)) {
      final prefix = asOtpPrefix(entry.value);
      if (prefix != null) {
        return prefix;
      }
    }
  }
  for (final key in const ['TOTPCode', 'Code', 'EmailCode', 'Token', 'token']) {
    final prefix = asOtpPrefix(fields[key]);
    if (prefix != null) {
      return prefix;
    }
  }

  final input = RegExp(r'<input\b([^>]*)>', caseSensitive: false);
  for (final match in input.allMatches(html)) {
    final attrs = match.group(1) ?? '';
    final lower = attrs.toLowerCase();
    if (!lower.contains('disabled') && !lower.contains('readonly')) {
      continue;
    }
    final prefix = asOtpPrefix(_attr(attrs, 'value'));
    if (prefix != null) {
      return prefix;
    }
  }

  final tag = RegExp(
    r'<(span|div|strong|label|p)\b([^>]*)>([^<]{1,12})</\1>',
    caseSensitive: false,
  );
  for (final match in tag.allMatches(html)) {
    final prefix = asOtpPrefix((match.group(3) ?? '').trim());
    if (prefix != null) {
      return prefix;
    }
  }

  return _otpStandalonePrefix.firstMatch(html)?.group(1);
}

/// JSON Authenticate bodies sometimes echo the same prefix.
String otpPrefixFromPayload(Map<String, dynamic> data) {
  for (final key in data.keys) {
    if (!isOtpPrefixFieldName(key) &&
        key.toLowerCase() != 'otpprefix' &&
        key.toLowerCase() != 'emailcodeprefix') {
      continue;
    }
    final prefix = asOtpPrefix(data[key]?.toString());
    if (prefix != null) {
      return prefix;
    }
  }
  return '';
}

/// Builds the Login2FA POST map. Named prefix field → keep prefix, send tail
/// in the code input. Display-only prefix (span) → concatenate into TOTPCode
/// the way official JS does.
Map<String, String> fillLogin2FaOtpFields({
  required Map<String, String> fields,
  required String prefix,
  required String tail,
}) {
  final next = Map<String, String>.from(fields);
  final normalizedPrefix = normalizeOtpPrefix(prefix);
  final normalizedTail = normalizeOtpTail(tail, prefix: normalizedPrefix);
  final composed = composeLogin2FaCode(
    prefix: normalizedPrefix,
    tail: normalizedTail,
  );

  String? prefixField;
  for (final key in next.keys) {
    if (isOtpPrefixFieldName(key)) {
      prefixField = key;
      break;
    }
  }
  if (prefixField != null) {
    next[prefixField] = normalizedPrefix;
  }

  final codeValue =
      prefixField != null && normalizedPrefix.isNotEmpty
          ? normalizedTail
          : composed;

  var wroteCode = false;
  for (final key in next.keys.toList()) {
    if (isOtpCodeFieldName(key)) {
      next[key] = codeValue;
      wroteCode = true;
    }
  }
  if (!wroteCode) {
    next['TOTPCode'] = codeValue;
  }
  return next;
}
