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

/// Wrong or expired one-time code.
final class NeptunOtpException extends NeptunException {
  const NeptunOtpException([
    super.message = 'Neptun rejected this code.',
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
