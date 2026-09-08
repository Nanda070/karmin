import 'package:dio/dio.dart';

import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_client.dart';
import 'package:karmin/auth/auth_models.dart';

/// ELTE public login is ASP.NET MVC (`LoginName` + `Password` to
/// `/Account/Login`), not the SDA JSON `ujhallgato` API.
///
/// After a valid password the portal sends the user to `/Account/Login2FA`.
/// Mail is **not** fired by the password POST. Official “E-mail code” is
/// `POST /Account/Login2FA` with `Phase=RequestEmail` and/or `Provider=Email`.
class EltePortalLogin {
  EltePortalLogin(this._client);

  static const String origin = 'https://neptun.elte.hu';
  static const String loginPath = '/Account/Login';
  static const String otpPath = '/Account/Login2FA';

  final NeptunClient _client;
  final Map<String, String> _cookies = {};
  Map<String, String> _otpFields = {};
  String _otpPrefix = '';
  String _otpHtml = '';
  var _hasSession = false;

  bool get hasSession => _hasSession;

  void clear() {
    _cookies.clear();
    _otpFields = {};
    _otpPrefix = '';
    _otpHtml = '';
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
      throw const NeptunApiException('Neptun request failed.');
    }
    fields['LoginName'] = code;
    fields['Password'] = password;
    fields.putIfAbsent('ReturnUrl', () => '');

    // Password POST opens Login2FA (often authenticator / a chooser). Mail
    // fires only when we POST the official E-mail code control.
    final response = await _post(loginPath, fields, referer: '$origin$loginPath');
    final ticket = await _ticketFromPortalResponse(response);
    if (ticket.step != NeptunAuthStep.needsOtp) {
      return ticket;
    }
    try {
      await _dispatchEmailCode(force: false);
    } on NeptunEmailCodeException {
      // Keep the 2FA session so the Verification screen can "Send code again".
      // Throwing here stranded users on Login with no resend control.
      if (!_hasSession) {
        rethrow;
      }
    }
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
    final ticket = await _ticketFromPortalResponse(response, treatingAsOtp: true);
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
    final previousHtml = _otpHtml;
    final previousSession = _hasSession;
    try {
      if (_hasSession || _otpFields.isNotEmpty) {
        try {
          await _dispatchEmailCode(force: true);
          return _emailOtpTicket();
        } on NeptunException {
          // 2FA session died; Login then the same send-email POST.
        }
      }
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
      _otpHtml = previousHtml;
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

  Future<void> _dispatchEmailCode({required bool force}) async {
    if (_otpFields.isEmpty || _otpHtml.isEmpty || force) {
      await _refreshOtpForm();
    }
    if (htmlLooksLikePasswordLogin(_otpHtml)) {
      _hasSession = false;
      throw const NeptunEmailCodeException();
    }
    if (!force && normalizeOtpPrefix(_otpPrefix).isNotEmpty) {
      return;
    }

    final previousPrefix = _otpPrefix;
    final button = findLogin2FaEmailSendControl(_otpHtml);
    final fields = fillLogin2FaSendEmailFields(
      fields: _otpFields,
      button: button,
    );
    final path = login2FaPostPath(button?.formAction);
    final response = await _post(path, fields, referer: '$origin$otpPath');
    await _applySendEmailResponse(response);
    if (normalizeOtpPrefix(_otpPrefix).isEmpty) {
      await _refreshOtpForm();
    }
    if (normalizeOtpPrefix(_otpPrefix).isEmpty &&
        normalizeOtpPrefix(previousPrefix).isNotEmpty) {
      _otpPrefix = previousPrefix;
    }
    if (normalizeOtpPrefix(_otpPrefix).isEmpty) {
      throw const NeptunEmailCodeException();
    }
  }

  Future<void> _refreshOtpForm() async {
    try {
      final response = await _sendGet(otpPath, referer: '$origin$loginPath');
      await _captureOtpResponse(response);
    } on NeptunException {
      // Keep whatever the previous response already captured.
    }
  }

  Future<void> _applySendEmailResponse(Response<dynamic> response) async {
    final status = response.statusCode ?? 0;
    final location = response.headers.value('location') ?? '';
    final html = _htmlOf(response);
    if (status == 429) {
      throw const NeptunLockoutException();
    }
    if (status >= 500) {
      throw NeptunApiException(
        'Neptun request failed.',
        statusCode: status,
      );
    }
    if (html.toLowerCase().contains('captcha')) {
      throw const NeptunCaptchaException();
    }
    if (htmlLooksLikePasswordLogin(html) ||
        (status >= 300 &&
            status < 400 &&
            location.toLowerCase().contains('login') &&
            !location.contains('Login2FA'))) {
      _hasSession = false;
      throw const NeptunEmailCodeException();
    }
    if (htmlLooksLikeOtp(html) || html.trim().isNotEmpty) {
      _captureOtpForm(html);
    }
    // Send-email often 302s to Login2FA with an empty body — follow for prefix.
    if (normalizeOtpPrefix(_otpPrefix).isEmpty &&
        _redirectsToLogin2Fa(status, location)) {
      await _refreshOtpForm();
    }
  }

  Future<void> _captureOtpResponse(Response<dynamic> response) async {
    final status = response.statusCode ?? 0;
    final location = response.headers.value('location') ?? '';
    final html = _htmlOf(response);
    if (htmlLooksLikePasswordLogin(html) ||
        (status >= 300 &&
            status < 400 &&
            location.toLowerCase().contains('login') &&
            !location.toLowerCase().contains('login2fa'))) {
      _hasSession = false;
      return;
    }
    if (htmlLooksLikeOtp(html) || html.trim().isNotEmpty) {
      _captureOtpForm(html);
      _hasSession = true;
      return;
    }
    if (_redirectsToLogin2Fa(status, location)) {
      _hasSession = true;
      final path = _pathFromLocation(location) ?? otpPath;
      final followed = await _sendGet(path, referer: '$origin$loginPath');
      final followedHtml = _htmlOf(followed);
      if (htmlLooksLikeOtp(followedHtml) || followedHtml.trim().isNotEmpty) {
        _captureOtpForm(followedHtml);
      }
    }
  }

  String? _pathFromLocation(String location) {
    final trimmed = location.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Uri.tryParse(trimmed)?.path;
    }
    final path = trimmed.split('?').first;
    if (path.startsWith('/')) {
      return path;
    }
    return '/$path';
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
    final headers = <String, dynamic>{
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'hu-HU,hu;q=0.9,en-US;q=0.8,en;q=0.7',
      'Origin': origin,
      'Referer': referer,
      'User-Agent': NeptunClient.portalUserAgent,
      'X-Requested-With': null,
      if (_cookies.isNotEmpty) 'Cookie': cookieHeader(_cookies),
    };
    // Never set content-type: null. Dio 5 treats that as conflicting with the
    // JSON default and throws ArgumentError before the request is sent.
    if (contentType != null) {
      headers[Headers.contentTypeHeader] = contentType;
    }
    return Options(
      followRedirects: false,
      maxRedirects: 0,
      validateStatus: (status) => status != null,
      responseType: ResponseType.plain,
      contentType: contentType,
      headers: headers,
    );
  }

  Future<AuthTicket> _ticketFromPortalResponse(
    Response<dynamic> response, {
    bool treatingAsOtp = false,
  }) async {
    final status = response.statusCode ?? 0;
    final location = response.headers.value('location') ?? '';
    final html = _htmlOf(response);

    if (status == 429) {
      throw const NeptunLockoutException();
    }
    if (status >= 500) {
      throw NeptunApiException(
        'Neptun request failed.',
        statusCode: status,
      );
    }
    if (html.toLowerCase().contains('captcha')) {
      throw const NeptunCaptchaException();
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
      await _captureOtpResponse(response);
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
      await _captureOtpResponse(response);
      _hasSession = true;
      return _emailOtpTicket();
    }

    throw const NeptunApiException('Neptun request failed.');
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
    _otpHtml = formHtml;
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
  for (final header in splitSetCookieHeaders(headers)) {
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
    if (value.isEmpty) {
      jar.remove(name);
      continue;
    }
    jar[name] = value;
  }
}

/// Dio/iOS sometimes folds several `Set-Cookie` lines into one comma-separated
/// header. `expires=Thu, 01 Jan 1970` also contains commas.
final _setCookieBoundary = RegExp(r',\s*(?=[^;,=\s]+=)');

Iterable<String> splitSetCookieHeaders(List<String>? headers) sync* {
  if (headers == null) {
    return;
  }
  for (final header in headers) {
    final trimmed = header.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    yield* trimmed.split(_setCookieBoundary);
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

/// Official E-mail code / send-code control on Login2FA (not the TOTP verify submit).
class Login2FaSubmitControl {
  const Login2FaSubmitControl({
    this.name,
    this.value = '',
    this.setvalTarget,
    this.setvalValue,
    this.text = '',
    this.formAction,
  });

  final String? name;
  final String value;
  final String? setvalTarget;
  final String? setvalValue;
  final String text;
  final String? formAction;

  String get blob =>
      '$name $value $setvalTarget $setvalValue $text $formAction'.toLowerCase();
}

final _buttonTag = RegExp(
  r'<button\b([^>]*)>(.*?)</button>',
  caseSensitive: false,
  dotAll: true,
);

const _emailSendFieldNames = {
  'sendcode',
  'sendemail',
  'sendemailcode',
  'requestemail',
  'emailcode',
};

const _emailProviderValues = {
  'email',
  'mail',
  'emailcode',
  'emailotp',
};

const _emailPhaseValues = {
  'requestemail',
  'sendemail',
  'email',
  'emailcode',
  'emailpreparation',
  'requestemailotp',
  'requestemailcode',
};

bool isEmailProviderValue(String? raw) {
  final value = (raw ?? '').trim().toLowerCase();
  return _emailProviderValues.contains(value);
}

bool isEmailCodePhase(String? raw) {
  final value = (raw ?? '').trim().toLowerCase();
  return _emailPhaseValues.contains(value);
}

bool _isAuthenticatorOnlyBlob(String blob) {
  final auth = blob.contains('authenticator') ||
      blob.contains('hiteles') ||
      blob.contains('totp');
  final mail = blob.contains('mail');
  return auth && !mail;
}

bool looksLikeEmailSendControl(Login2FaSubmitControl control) {
  final blob = control.blob;
  if (_isAuthenticatorOnlyBlob(blob)) {
    return false;
  }
  final name = (control.name ?? '').toLowerCase();
  final value = control.value.toLowerCase();
  if (name.contains('provider') && isEmailProviderValue(value)) {
    return true;
  }
  if (_emailSendFieldNames.contains(name)) {
    return true;
  }
  if (isEmailCodePhase(control.setvalValue) || isEmailCodePhase(control.value)) {
    return true;
  }
  return blob.contains('e-mail') ||
      blob.contains('email') ||
      RegExp(r'(^|[^a-z])mail([^a-z]|$)').hasMatch(blob);
}

List<Login2FaSubmitControl> extractLogin2FaSubmitControls(String html) {
  final controls = <Login2FaSubmitControl>[];
  for (final match in _buttonTag.allMatches(html)) {
    final attrs = match.group(1) ?? '';
    final type = (_attr(attrs, 'type') ?? 'submit').toLowerCase();
    if (type == 'reset') {
      continue;
    }
    final setvalTarget = _attr(attrs, 'data-setval-target');
    final setvalValue = _attr(attrs, 'data-setval-value');
    final name = _attr(attrs, 'name');
    final value = _attr(attrs, 'value') ?? '';
    final text =
        (match.group(2) ?? '').replaceAll(RegExp(r'<[^>]+>'), '').trim();
    // Potlap often uses type="button" + data-setval, then JS submits the form.
    if (type == 'button' &&
        (setvalTarget == null || setvalTarget.isEmpty) &&
        !looksLikeEmailSendControl(
          Login2FaSubmitControl(
            name: name,
            value: value,
            setvalTarget: setvalTarget,
            setvalValue: setvalValue,
            text: text,
          ),
        )) {
      continue;
    }
    controls.add(
      Login2FaSubmitControl(
        name: name,
        value: value,
        setvalTarget: setvalTarget,
        setvalValue: setvalValue,
        text: text,
        formAction: _attr(attrs, 'formaction'),
      ),
    );
  }
  final input = RegExp(r'<input\b([^>]*)>', caseSensitive: false);
  for (final match in input.allMatches(html)) {
    final attrs = match.group(1) ?? '';
    final type = (_attr(attrs, 'type') ?? '').toLowerCase();
    if (type != 'submit') {
      continue;
    }
    controls.add(
      Login2FaSubmitControl(
        name: _attr(attrs, 'name'),
        value: _attr(attrs, 'value') ?? '',
        setvalTarget: _attr(attrs, 'data-setval-target'),
        setvalValue: _attr(attrs, 'data-setval-value'),
        text: _attr(attrs, 'value') ?? '',
        formAction: _attr(attrs, 'formaction'),
      ),
    );
  }
  // <a class="btn" data-setval-…>E-mail code</a>
  final anchor = RegExp(
    r'<a\b([^>]*)>(.*?)</a>',
    caseSensitive: false,
    dotAll: true,
  );
  for (final match in anchor.allMatches(html)) {
    final attrs = match.group(1) ?? '';
    final setvalTarget = _attr(attrs, 'data-setval-target');
    if (setvalTarget == null || setvalTarget.isEmpty) {
      continue;
    }
    controls.add(
      Login2FaSubmitControl(
        name: _attr(attrs, 'name'),
        value: _attr(attrs, 'value') ?? '',
        setvalTarget: setvalTarget,
        setvalValue: _attr(attrs, 'data-setval-value'),
        text: (match.group(2) ?? '').replaceAll(RegExp(r'<[^>]+>'), '').trim(),
        formAction: _attr(attrs, 'href') ?? _attr(attrs, 'formaction'),
      ),
    );
  }
  return controls;
}

Login2FaSubmitControl? findLogin2FaEmailSendControl(String html) {
  final matches =
      extractLogin2FaSubmitControls(html).where(looksLikeEmailSendControl);
  for (final control in matches) {
    return control;
  }
  return null;
}

String login2FaPostPath(String? formAction) {
  if (formAction == null || formAction.trim().isEmpty) {
    return EltePortalLogin.otpPath;
  }
  final raw = formAction.trim();
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    final path = Uri.tryParse(raw)?.path;
    if (path != null && path.isNotEmpty) {
      return path;
    }
    return EltePortalLogin.otpPath;
  }
  final path = raw.split('?').first;
  if (path.startsWith('/')) {
    return path;
  }
  return '/$path';
}

String? _fieldKeyIgnoringCase(Map<String, String> fields, String name) {
  if (fields.containsKey(name)) {
    return name;
  }
  final lower = name.toLowerCase();
  for (final key in fields.keys) {
    if (key.toLowerCase() == lower) {
      return key;
    }
  }
  return null;
}

/// Builds the Login2FA POST that official “E-mail code” uses to dispatch mail.
Map<String, String> fillLogin2FaSendEmailFields({
  required Map<String, String> fields,
  Login2FaSubmitControl? button,
}) {
  final next = Map<String, String>.from(fields);
  // Do not POST an empty TOTPCode as a verify attempt while requesting email.
  for (final key in next.keys.toList()) {
    if (isOtpCodeFieldName(key)) {
      next.remove(key);
    }
  }

  if (button != null) {
    final target = button.setvalTarget;
    if (target != null && target.isNotEmpty) {
      final key = _fieldKeyIgnoringCase(next, target) ?? target;
      next[key] = button.setvalValue ?? '';
    }
    if (button.name != null && button.name!.isNotEmpty) {
      next[button.name!] = button.value;
    }
    // If the control only sets Provider=Email, also force an email Phase when
    // the page is still on authenticator RequestTOTP.
    final phaseKey = _fieldKeyIgnoringCase(next, 'Phase');
    final phase = phaseKey == null ? '' : next[phaseKey]!;
    if (button.name?.toLowerCase() == 'provider' &&
        isEmailProviderValue(button.value) &&
        !isEmailCodePhase(phase)) {
      if (phaseKey != null) {
        next[phaseKey] = 'RequestEmail';
      } else {
        next['Phase'] = 'RequestEmail';
      }
    }
    return next;
  }

  for (final key in const ['Provider', 'SelectedProvider']) {
    final existing = _fieldKeyIgnoringCase(next, key);
    if (existing != null) {
      next[existing] = 'Email';
    }
  }
  if (_fieldKeyIgnoringCase(next, 'Provider') == null) {
    next['Provider'] = 'Email';
  }

  final phaseKey = _fieldKeyIgnoringCase(next, 'Phase');
  final phase = phaseKey == null ? '' : next[phaseKey]!;
  if (!isEmailCodePhase(phase)) {
    if (phaseKey != null) {
      next[phaseKey] = 'RequestEmail';
    } else {
      next['Phase'] = 'RequestEmail';
    }
  }
  return next;
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
