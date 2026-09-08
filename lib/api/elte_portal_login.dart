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
  var _hasSession = false;

  bool get hasSession => _hasSession;

  void clear() {
    _cookies.clear();
    _otpFields = {};
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
    if (ticket.step == NeptunAuthStep.needsOtp && _otpFields.isEmpty) {
      try {
        final html = await _get(otpPath);
        _otpFields = extractNamedInputs(html);
      } on NeptunException {
        // OTP submit will GET Login2FA again with the session cookie.
      }
    }
    return ticket;
  }

  Future<AuthTicket> submitOtp({
    required String otp,
  }) async {
    var fields = Map<String, String>.from(_otpFields);
    if (fields.isEmpty) {
      final html = await _get(otpPath);
      fields = extractNamedInputs(html);
    }
    final code = otp.trim();
    for (final key in const [
      'TOTPCode',
      'Code',
      'EmailCode',
      'OneTimeCode',
      'token',
      'Token',
    ]) {
      if (fields.containsKey(key) || key == 'TOTPCode') {
        fields[key] = code;
      }
    }

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
      _otpFields = extractNamedInputs(html);
      _hasSession = true;
      if (html.trim().isEmpty && location.contains('Login2FA')) {
        // 302 to 2FA — fetch the form so OTP can be posted.
        return AuthTicket(
          step: NeptunAuthStep.needsOtp,
          otpChannel: otpChannelFromHtml(html, location),
        );
      }
      return AuthTicket(
        step: NeptunAuthStep.needsOtp,
        otpChannel: otpChannelFromHtml(html, location),
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
