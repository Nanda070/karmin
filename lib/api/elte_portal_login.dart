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
    final loginHtml = await _fetchPasswordLoginHtml();
    final fields = extractLoginFormFields(loginHtml);
    if ((fields['__RequestVerificationToken'] ?? '').isEmpty) {
      throw const NeptunUnavailableException();
    }
    fields['LoginName'] = code;
    fields['Password'] = password;
    fields.putIfAbsent('ReturnUrl', () => '');

    // Mail is dispatched only on a successful MVC password POST, same as Safari.
    final response = await _post(loginPath, fields, referer: '$origin$loginPath');
    final ticket = _ticketFromPortalResponse(response);
    if (ticket.step != NeptunAuthStep.needsOtp) {
      return ticket;
    }
    await _scrapeLogin2FaPrefix();
    return _emailOtpTicket();
  }

  Future<AuthTicket> submitOtp({
    required String otp,
  }) async {
    if (normalizeOtpPrefix(_otpPrefix).isEmpty) {
      // Email Login2FA expects prefix+tail (`732-893600`). A bare 6-digit TOTP
      // is the authenticator payload and is rejected on the email form.
      throw const NeptunOtpException();
    }
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
  }) async {
    final previousCookies = Map<String, String>.from(_cookies);
    final previousFields = Map<String, String>.from(_otpFields);
    final previousPrefix = _otpPrefix;
    final previousSession = _hasSession;
    try {
      clear();
      return await submitPassword(
        userName: userName,
        password: password,
        lcid: lcid,
      );
    } catch (_) {
      _cookies
        ..clear()
        ..addAll(previousCookies);
      _otpFields = previousFields;
      _otpPrefix = previousPrefix;
      _hasSession = previousSession;
      rethrow;
    }
  }

  Future<String> _fetchPasswordLoginHtml() async {
    var response = await _sendGet(loginPath, referer: '$origin$loginPath');
    var html = _htmlOf(response);
    final location = response.headers.value('location') ?? '';
    if (_redirectsToLogin2Fa(response.statusCode, location) ||
        htmlLooksLikeOtp(html)) {
      // A pending 2FA session makes GET Login bounce to Login2FA (no mail).
      _cookies.clear();
      response = await _sendGet(loginPath, referer: '$origin$loginPath');
      html = _htmlOf(response);
    }
    return html;
  }

  Future<void> _scrapeLogin2FaPrefix() async {
    if (_otpFields.isNotEmpty && _otpPrefix.isNotEmpty) {
      return;
    }
    try {
      final otpHtml = await _get(otpPath);
      _captureOtpForm(otpHtml);
    } on NeptunException {
      // Prefix stays whatever the Login POST body already captured.
    }
  }

  AuthTicket _emailOtpTicket() {
    return AuthTicket(
      step: NeptunAuthStep.needsOtp,
      otpChannel: OtpChannel.email,
      otpPrefix: _otpPrefix,
    );
  }

  Future<String> _get(String path) async {
    return _htmlOf(await _sendGet(path, referer: '$origin$loginPath'));
  }

  Future<Response<dynamic>> _sendGet(String path, {required String referer}) async {
    try {
      final response = await _client.dio.get<dynamic>(
        '$origin$path',
        options: _options(referer: referer),
      );
      _storeCookies(response);
      return response;
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
        data: encodeFormBody(fields),
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
      maxRedirects: 0,
      validateStatus: (status) => status != null && status < 500,
      responseType: ResponseType.plain,
      contentType: contentType,
      headers: <String, dynamic>{
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'hu-HU,hu;q=0.9,en-US;q=0.8,en;q=0.7',
        'Origin': origin,
        'Referer': referer,
        // NeptunClient defaults to XHR+JSON; that AJAX path does not mail OTP.
        'X-Requested-With': null,
        Headers.contentTypeHeader: contentType,
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
      return _emailOtpTicket();
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

    if (_redirectsToLogin2Fa(status, location)) {
      _hasSession = true;
      return _emailOtpTicket();
    }

    throw const NeptunUnavailableException();
  }

  bool _isOtpChallenge(int status, String location, String html) {
    if (_redirectsToLogin2Fa(status, location)) {
      return true;
    }
    if (htmlLooksLikePasswordLogin(html)) {
      return false;
    }
    return htmlLooksLikeOtp(html);
  }

  bool _redirectsToLogin2Fa(int? status, String location) {
    return status != null &&
        status >= 300 &&
        status < 400 &&
        location.toLowerCase().contains('login2fa');
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
    if (html.trim().isEmpty || htmlLooksLikePasswordLogin(html)) {
      return;
    }
    final formHtml = htmlOfLogin2FaForm(html) ?? html;
    final fields = extractNamedInputs(formHtml);
    if (fields.isNotEmpty) {
      _otpFields = fields;
    }
    final prefix = parseLogin2FaPrefix(formHtml);
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

/// `application/x-www-form-urlencoded`. Dio 5 only url-encodes
/// `Map<String, dynamic>`; `Map<String, String>` is sent as `{key: value}`.
String encodeFormBody(Map<String, String> fields) {
  return fields.entries
      .map(
        (entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
      )
      .join('&');
}

String? htmlOfForm(
  String html, {
  required bool Function(String attrs, String body) match,
}) {
  final form = RegExp(
    r'<form\b([^>]*)>(.*?)</form>',
    caseSensitive: false,
    dotAll: true,
  );
  for (final found in form.allMatches(html)) {
    if (match(found.group(1) ?? '', found.group(2) ?? '')) {
      return found.group(0);
    }
  }
  return null;
}

bool _actionIsPasswordLogin(String action) {
  final path = action.split('?').first.toLowerCase();
  if (path.contains('login2fa')) {
    return false;
  }
  return path.endsWith('/account/login') || path.endsWith('account/login');
}

bool _actionIsLogin2Fa(String action) {
  return action.split('?').first.toLowerCase().contains('login2fa');
}

/// Fields from the password form only — not language/theme switchers.
Map<String, String> extractLoginFormFields(String html) {
  final form = htmlOfForm(
    html,
    match: (attrs, body) {
      if (_actionIsPasswordLogin(_attr(attrs, 'action') ?? '')) {
        return true;
      }
      final lower = body.toLowerCase();
      return (lower.contains('name="loginname"') ||
              lower.contains("name='loginname'")) &&
          !_actionIsLogin2Fa(_attr(attrs, 'action') ?? '');
    },
  );
  return extractNamedInputs(form ?? html);
}

String? htmlOfLogin2FaForm(String html) {
  return htmlOfForm(
    html,
    match: (attrs, body) {
      if (_actionIsLogin2Fa(_attr(attrs, 'action') ?? '')) {
        return true;
      }
      final lower = body.toLowerCase();
      return lower.contains('totpcode') ||
          lower.contains('name="phase"') ||
          lower.contains("name='phase'");
    },
  );
}

bool htmlLooksLikePasswordLogin(String html) {
  final lower = html.toLowerCase();
  final hasLoginName =
      lower.contains('name="loginname"') || lower.contains("name='loginname'");
  if (!hasLoginName) {
    return false;
  }
  return !lower.contains('login2fa') && !lower.contains('totpcode');
}

bool htmlLooksLikeOtp(String html) {
  if (htmlLooksLikePasswordLogin(html)) {
    return false;
  }
  final lower = html.toLowerCase();
  return lower.contains('login2fa') ||
      lower.contains('totpcode') ||
      lower.contains('name="phase"') ||
      lower.contains("name='phase'");
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
