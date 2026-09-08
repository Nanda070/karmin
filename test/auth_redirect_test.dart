import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/auth/auth_models.dart';
import 'package:karmin/auth/auth_redirect.dart';

void main() {
  AuthState base({
    bool hydrated = true,
    bool disclaimer = true,
    bool credentials = false,
    bool pin = false,
    bool unlocked = false,
    NeptunAuthStep step = NeptunAuthStep.needsPassword,
  }) {
    return AuthState(
      hydrated: hydrated,
      disclaimerAccepted: disclaimer,
      hasCredentials: credentials,
      hasPin: pin,
      unlocked: unlocked,
      neptunStep: step,
      bioEnabled: false,
      bioAvailable: false,
    );
  }

  test('boot while hydrating', () {
    expect(authRedirect(base(hydrated: false), '/today'), '/boot');
    expect(authRedirect(base(hydrated: false), '/boot'), isNull);
  });

  test('disclaimer then login', () {
    expect(authRedirect(base(disclaimer: false), '/today'), '/disclaimer');
    expect(authRedirect(base(), '/today'), '/login');
  });

  test('password accepted goes to verification', () {
    expect(
      authRedirect(base(step: NeptunAuthStep.needsOtp), '/login'),
      '/verify',
    );
  });

  test('cold start with vault locked goes to unlock', () {
    expect(
      authRedirect(
        base(credentials: true, pin: true),
        '/today',
      ),
      '/unlock',
    );
  });

  test('unlock then OTP when JWT is missing', () {
    expect(
      authRedirect(
        base(
          credentials: true,
          pin: true,
          unlocked: true,
          step: NeptunAuthStep.needsOtp,
        ),
        '/unlock',
      ),
      '/verify',
    );
  });

  test('first session after OTP sets PIN', () {
    expect(
      authRedirect(
        base(
          credentials: true,
          unlocked: true,
          step: NeptunAuthStep.authenticated,
        ),
        '/verify',
      ),
      '/set-pin',
    );
  });

  test('authenticated and unlocked reaches Today', () {
    expect(
      authRedirect(
        base(
          credentials: true,
          pin: true,
          unlocked: true,
          step: NeptunAuthStep.authenticated,
        ),
        '/login',
      ),
      '/today',
    );
    expect(
      authRedirect(
        base(
          credentials: true,
          pin: true,
          unlocked: true,
          step: NeptunAuthStep.authenticated,
        ),
        '/today',
      ),
      isNull,
    );
  });
}
