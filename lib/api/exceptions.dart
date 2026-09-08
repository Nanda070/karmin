/// User-facing status line. Never pass password or OTP digits in [neptunMessage].
String formatNeptunStatusMessage({
  required String fallback,
  int? statusCode,
  String? neptunMessage,
}) {
  final raw = neptunMessage?.trim();
  final detail = (raw == null || raw.isEmpty)
      ? null
      : (raw.length > 120 ? '${raw.substring(0, 120)}…' : raw);
  if (statusCode != null && detail != null) {
    return '$fallback (HTTP $statusCode): $detail';
  }
  if (statusCode != null) {
    return '$fallback (HTTP $statusCode)';
  }
  if (detail != null) {
    return '$fallback: $detail';
  }
  return fallback;
}

/// Typed failures for Neptun HTTP / auth flows (Stage 1+).
sealed class NeptunException implements Exception {
  const NeptunException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Wrong Neptun code or password.
final class NeptunAuthException extends NeptunException {
  const NeptunAuthException([
    super.message = 'Neptun rejected these credentials.',
  ]);

  factory NeptunAuthException.reject({
    int? statusCode,
    String? neptunMessage,
  }) {
    return NeptunAuthException(
      formatNeptunStatusMessage(
        fallback: 'Neptun rejected these credentials',
        statusCode: statusCode,
        neptunMessage: neptunMessage,
      ),
    );
  }
}

/// DNS / timeout / no connectivity.
final class NeptunNetworkException extends NeptunException {
  const NeptunNetworkException([super.message = "Can't reach Neptun."]);
}

/// HTTP 202 / captcha challenge from Neptun.
final class NeptunCaptchaException extends NeptunException {
  const NeptunCaptchaException([
    super.message =
        'Neptun wants a captcha. Sign in once on the website, then retry.',
  ]);
}

/// HTTP 429 / repeated failures — not invalid credentials.
final class NeptunLockoutException extends NeptunException {
  const NeptunLockoutException([
    super.message = 'Too many tries. Wait a moment, then sign in again.',
  ]);
}

/// JSON student API missing/stub — not invalid credentials, not a transport failure.
/// Prefer [NeptunUnavailableException.detail] so the UI shows HTTP status.
final class NeptunUnavailableException extends NeptunException {
  const NeptunUnavailableException([
    super.message =
        'ELTE student login returned an error. Try again, or sign in on the website.',
  ]);

  factory NeptunUnavailableException.detail({
    int? statusCode,
    String? neptunMessage,
  }) {
    return NeptunUnavailableException(
      formatNeptunStatusMessage(
        fallback: 'ELTE student login returned an error',
        statusCode: statusCode,
        neptunMessage: neptunMessage,
      ),
    );
  }
}

/// HTML / maintenance page instead of JSON student data.
final class NeptunMaintenanceException extends NeptunException {
  const NeptunMaintenanceException([
    super.message =
        'Neptun is temporarily unavailable (maintenance or web page).',
  ]);

  factory NeptunMaintenanceException.detail({int? statusCode}) {
    if (statusCode == null) {
      return const NeptunMaintenanceException();
    }
    return NeptunMaintenanceException(
      'Neptun is temporarily unavailable (maintenance or web page, HTTP $statusCode).',
    );
  }
}

/// Signed in via MVC cookies only — student JSON needs a real Authenticate JWT.
final class NeptunPortalSessionException extends NeptunException {
  const NeptunPortalSessionException([
    super.message =
        'Web login succeeded, but live calendar needs a JSON Neptun session. Sign out and sign in again with Authenticator.',
  ]);
}

/// Wrong or expired one-time code.
///
/// Prefer [NeptunOtpException.reject] so Verification can show HTTP status /
/// Neptun text without logging secrets (never put password/OTP in [message]).
final class NeptunOtpException extends NeptunException {
  const NeptunOtpException([
    super.message = 'Neptun rejected this code.',
  ]);

  /// User-facing detail, e.g. `Neptun rejected this code (HTTP 400)` or with
  /// a short Neptun server phrase. Truncates long text; never includes secrets.
  factory NeptunOtpException.reject({
    int? statusCode,
    String? neptunMessage,
  }) {
    if (statusCode == null &&
        (neptunMessage == null || neptunMessage.trim().isEmpty)) {
      return const NeptunOtpException();
    }
    return NeptunOtpException(
      formatNeptunStatusMessage(
        fallback: 'Neptun rejected this code',
        statusCode: statusCode,
        neptunMessage: neptunMessage,
      ),
    );
  }
}

/// Login2FA never dispatched the email OTP (chooser not POSTed, or send failed).
final class NeptunEmailCodeException extends NeptunException {
  const NeptunEmailCodeException([
    super.message =
        'Neptun did not send an email code. Try Send code again, or tap E-mail code on the website.',
  ]);
}

/// JWT died; UI must collect a new OTP (password may be replayed from Keystore).
final class NeptunSessionExpiredException extends NeptunException {
  const NeptunSessionExpiredException([
    super.message = 'Neptun session expired. Enter a new one-time code.',
  ]);
}

/// Unexpected status or payload shape.
final class NeptunApiException extends NeptunException {
  const NeptunApiException(
    super.message, {
    this.statusCode,
  });

  final int? statusCode;
}

/// Feature denied (HTTP 403) — UI should hide the tile.
final class NeptunForbiddenException extends NeptunException {
  const NeptunForbiddenException([
    super.message = 'This feature is not available for your account.',
  ]);
}
