/// Neptun authentication progress. PIN/biometrics are a separate local lock.
enum NeptunAuthStep {
  needsPassword,
  needsOtp,
  authenticated,
}

/// Best-effort OTP channel. Unknown → copy mentions email or authenticator.
enum OtpChannel {
  email,
  authenticator,
  unknown,
}

/// Result of a password or OTP attempt. JWT is never written to disk.
class AuthTicket {
  const AuthTicket({
    required this.step,
    this.accessToken,
    this.neptunCode,
    this.otpChannel = OtpChannel.unknown,
  });

  final NeptunAuthStep step;
  final String? accessToken;
  final String? neptunCode;
  final OtpChannel otpChannel;

  bool get hasJwt =>
      step == NeptunAuthStep.authenticated &&
      accessToken != null &&
      accessToken!.isNotEmpty;
}

/// Immutable UI/session snapshot. Pending password lives only in the controller.
class AuthState {
  const AuthState({
    required this.hydrated,
    required this.disclaimerAccepted,
    required this.hasCredentials,
    required this.hasPin,
    required this.unlocked,
    required this.neptunStep,
    required this.bioEnabled,
    required this.bioAvailable,
    this.neptunCode,
    this.otpChannel = OtpChannel.unknown,
    this.busy = false,
    this.errorMessage,
    this.pinLockedUntil,
    this.pinAttempts = 0,
    this.usingDebugAuth = false,
    this.otpResendAvailableAt,
    this.otpResendNonce = 0,
  });

  factory AuthState.loading({bool usingDebugAuth = false}) {
    return AuthState(
      hydrated: false,
      disclaimerAccepted: false,
      hasCredentials: false,
      hasPin: false,
      unlocked: false,
      neptunStep: NeptunAuthStep.needsPassword,
      bioEnabled: false,
      bioAvailable: false,
      usingDebugAuth: usingDebugAuth,
    );
  }

  /// Signed-in shell for widget tests / smoke.
  factory AuthState.unlockedSession({
    String neptunCode = 'ABC123',
    bool usingDebugAuth = true,
  }) {
    return AuthState(
      hydrated: true,
      disclaimerAccepted: true,
      hasCredentials: true,
      hasPin: true,
      unlocked: true,
      neptunStep: NeptunAuthStep.authenticated,
      bioEnabled: false,
      bioAvailable: false,
      neptunCode: neptunCode,
      usingDebugAuth: usingDebugAuth,
    );
  }

  final bool hydrated;
  final bool disclaimerAccepted;
  final bool hasCredentials;
  final bool hasPin;
  final bool unlocked;
  final NeptunAuthStep neptunStep;
  final bool bioEnabled;
  final bool bioAvailable;
  final String? neptunCode;
  final OtpChannel otpChannel;
  final bool busy;
  final String? errorMessage;
  final DateTime? pinLockedUntil;
  final int pinAttempts;
  final bool usingDebugAuth;

  /// After a successful resend-via-relogin, tap is ignored until this instant.
  final DateTime? otpResendAvailableAt;

  /// Bumps when a new OTP mail was requested so the Verification UI can toast.
  final int otpResendNonce;

  bool get pinIsLocked =>
      pinLockedUntil != null && DateTime.now().isBefore(pinLockedUntil!);

  bool get hasLiveJwt => neptunStep == NeptunAuthStep.authenticated;

  int otpResendSecondsRemaining([DateTime? now]) {
    final until = otpResendAvailableAt;
    if (until == null) {
      return 0;
    }
    final seconds = until.difference(now ?? DateTime.now()).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  bool otpResendReady([DateTime? now]) =>
      otpResendSecondsRemaining(now) == 0 && !busy;

  AuthState copyWith({
    bool? hydrated,
    bool? disclaimerAccepted,
    bool? hasCredentials,
    bool? hasPin,
    bool? unlocked,
    NeptunAuthStep? neptunStep,
    bool? bioEnabled,
    bool? bioAvailable,
    String? neptunCode,
    bool clearNeptunCode = false,
    OtpChannel? otpChannel,
    bool? busy,
    String? errorMessage,
    bool clearError = false,
    DateTime? pinLockedUntil,
    bool clearPinLock = false,
    int? pinAttempts,
    bool? usingDebugAuth,
    DateTime? otpResendAvailableAt,
    bool clearOtpResend = false,
    int? otpResendNonce,
  }) {
    return AuthState(
      hydrated: hydrated ?? this.hydrated,
      disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
      hasCredentials: hasCredentials ?? this.hasCredentials,
      hasPin: hasPin ?? this.hasPin,
      unlocked: unlocked ?? this.unlocked,
      neptunStep: neptunStep ?? this.neptunStep,
      bioEnabled: bioEnabled ?? this.bioEnabled,
      bioAvailable: bioAvailable ?? this.bioAvailable,
      neptunCode: clearNeptunCode ? null : (neptunCode ?? this.neptunCode),
      otpChannel: otpChannel ?? this.otpChannel,
      busy: busy ?? this.busy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pinLockedUntil:
          clearPinLock ? null : (pinLockedUntil ?? this.pinLockedUntil),
      pinAttempts: pinAttempts ?? this.pinAttempts,
      usingDebugAuth: usingDebugAuth ?? this.usingDebugAuth,
      otpResendAvailableAt: clearOtpResend
          ? null
          : (otpResendAvailableAt ?? this.otpResendAvailableAt),
      otpResendNonce: otpResendNonce ?? this.otpResendNonce,
    );
  }
}
