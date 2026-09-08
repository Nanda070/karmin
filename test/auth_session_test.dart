import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/api/neptun_auth.dart';
import 'package:karmin/api/neptun_client.dart';
import 'package:karmin/auth/auth_controller.dart';
import 'package:karmin/auth/auth_models.dart';
import 'package:karmin/auth/local_auth_probe.dart';
import 'package:karmin/auth/prefs.dart';
import 'package:karmin/auth/secure_storage_keys.dart';
import 'package:karmin/auth/secure_store.dart';

void main() {
  AuthController build() {
    return AuthController(
      store: MemorySecureStore(),
      prefs: MemoryPrefsStore(),
      authApi: DebugNeptunAuth(),
      client: NeptunClient(),
      localAuth: LocalAuthProbe(),
      usingDebugAuth: true,
      hydrateOnStart: false,
    );
  }

  test('debug login requires OTP before storing credentials', () async {
    final controller = build();
    await controller.acceptDisclaimer();
    await controller.login(
      userName: 'abc123',
      password: 'secret',
      lcid: 1033,
    );
    expect(controller.state.neptunStep, NeptunAuthStep.needsOtp);
    expect(controller.state.hasCredentials, isFalse);
  });

  test('OTP then PIN yields an in-memory JWT', () async {
    final store = MemorySecureStore();
    final client = NeptunClient();
    final controller = AuthController(
      store: store,
      prefs: MemoryPrefsStore(),
      authApi: DebugNeptunAuth(),
      client: client,
      localAuth: LocalAuthProbe(),
      usingDebugAuth: true,
      hydrateOnStart: false,
    );

    await controller.acceptDisclaimer();
    await controller.login(userName: 'abc123', password: 'secret', lcid: 1033);
    await controller.submitOtp(otp: '123456', lcid: 1033);

    expect(controller.state.neptunStep, NeptunAuthStep.authenticated);
    expect(controller.state.hasCredentials, isTrue);
    expect(client.hasJwt, isTrue);
    expect(store.data[SecureStorageKeys.neptunPassword], 'secret');

    await controller.setPin('654321', enableBio: false);
    expect(controller.state.hasPin, isTrue);
    expect(controller.state.unlocked, isTrue);
  });

  test('cold unlock without JWT asks for OTP again', () async {
    final store = MemorySecureStore();
    final client = NeptunClient();
    final controller = AuthController(
      store: store,
      prefs: MemoryPrefsStore()..disclaimerAccepted = true,
      authApi: DebugNeptunAuth(),
      client: client,
      localAuth: LocalAuthProbe(),
      usingDebugAuth: true,
      hydrateOnStart: false,
    );

    await controller.acceptDisclaimer();
    await controller.login(userName: 'abc123', password: 'secret', lcid: 1033);
    await controller.submitOtp(otp: '111111', lcid: 1033);
    await controller.setPin('654321', enableBio: false);

    client.clearSession();
    controller.lockLocally();
    expect(controller.state.unlocked, isFalse);

    final ok = await controller.unlockWithPin('654321');
    expect(ok, isTrue);
    expect(controller.state.unlocked, isTrue);
    expect(controller.state.neptunStep, NeptunAuthStep.needsOtp);
    expect(client.hasJwt, isFalse);
  });

  test('warm unlock keeps JWT and skips OTP', () async {
    final client = NeptunClient();
    final controller = AuthController(
      store: MemorySecureStore(),
      prefs: MemoryPrefsStore(),
      authApi: DebugNeptunAuth(),
      client: client,
      localAuth: LocalAuthProbe(),
      usingDebugAuth: true,
      hydrateOnStart: false,
    );

    await controller.acceptDisclaimer();
    await controller.login(userName: 'abc123', password: 'secret', lcid: 1033);
    await controller.submitOtp(otp: '222222', lcid: 1033);
    await controller.setPin('654321', enableBio: false);
    controller.lockLocally();

    expect(client.hasJwt, isTrue);
    await controller.unlockWithPin('654321');
    expect(controller.state.neptunStep, NeptunAuthStep.authenticated);
  });

  test('sign out clears vault and JWT', () async {
    final store = MemorySecureStore();
    final client = NeptunClient();
    final controller = AuthController(
      store: store,
      prefs: MemoryPrefsStore(),
      authApi: DebugNeptunAuth(),
      client: client,
      localAuth: LocalAuthProbe(),
      usingDebugAuth: true,
      hydrateOnStart: false,
    );

    await controller.login(userName: 'abc123', password: 'secret', lcid: 1033);
    await controller.submitOtp(otp: '333333', lcid: 1033);
    await controller.setPin('654321', enableBio: false);
    await controller.signOut();

    expect(controller.state.hasCredentials, isFalse);
    expect(controller.state.hasPin, isFalse);
    expect(client.hasJwt, isFalse);
    expect(store.data, isEmpty);
  });

  test('401 replay asks for OTP again', () async {
    final store = MemorySecureStore();
    final client = NeptunClient();
    var passwords = 0;
    final controller = AuthController(
      store: store,
      prefs: MemoryPrefsStore(),
      authApi: _CountingAuth(onPassword: () => passwords += 1),
      client: client,
      localAuth: LocalAuthProbe(),
      usingDebugAuth: true,
      hydrateOnStart: false,
    );

    await controller.acceptDisclaimer();
    await controller.login(userName: 'abc123', password: 'secret', lcid: 1033);
    await controller.submitOtp(otp: '444444', lcid: 1033);
    await controller.setPin('654321', enableBio: false);
    expect(client.hasJwt, isTrue);

    client.clearSession();
    controller.onUnauthorized();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(client.hasJwt, isFalse);
    expect(controller.state.neptunStep, NeptunAuthStep.needsOtp);
    expect(passwords, greaterThanOrEqualTo(2));
  });

  test('resend-via-relogin stays on OTP and cools down', () async {
    var now = DateTime(2026, 9, 8, 8);
    var passwords = 0;
    final controller = AuthController(
      store: MemorySecureStore(),
      prefs: MemoryPrefsStore(),
      authApi: _CountingAuth(onPassword: () => passwords += 1),
      client: NeptunClient(),
      localAuth: LocalAuthProbe(),
      usingDebugAuth: true,
      hydrateOnStart: false,
      otpResendCooldown: const Duration(seconds: 30),
      clock: () => now,
    );

    await controller.login(userName: 'abc123', password: 'secret', lcid: 1033);
    expect(controller.state.neptunStep, NeptunAuthStep.needsOtp);
    expect(passwords, 1);

    await controller.resendEmailCode(lcid: 1033);
    expect(controller.state.neptunStep, NeptunAuthStep.needsOtp);
    expect(controller.state.otpResendNonce, 1);
    expect(controller.state.errorMessage, isNull);
    expect(passwords, 2);

    await controller.resendEmailCode(lcid: 1033);
    expect(passwords, 2);

    now = now.add(const Duration(seconds: 31));
    await controller.resendEmailCode(lcid: 1033);
    expect(passwords, 3);
    expect(controller.state.otpResendNonce, 2);
  });

  test('resend can reload password from Keystore', () async {
    final store = MemorySecureStore();
    var passwords = 0;
    final controller = AuthController(
      store: store,
      prefs: MemoryPrefsStore(),
      authApi: _CountingAuth(onPassword: () => passwords += 1),
      client: NeptunClient(),
      localAuth: LocalAuthProbe(),
      usingDebugAuth: true,
      hydrateOnStart: false,
    );

    await controller.login(userName: 'abc123', password: 'secret', lcid: 1033);
    await controller.submitOtp(otp: '555555', lcid: 1033);
    expect(store.data[SecureStorageKeys.neptunPassword], 'secret');

    controller.debugSetState(
      controller.state.copyWith(neptunStep: NeptunAuthStep.needsOtp),
    );
    await controller.resendEmailCode(lcid: 1033);
    expect(controller.state.neptunStep, NeptunAuthStep.needsOtp);
    expect(controller.state.otpResendNonce, 1);
    expect(passwords, 2);
  });
}

class _CountingAuth implements NeptunAuthApi {
  _CountingAuth({this.onPassword});

  final void Function()? onPassword;

  @override
  Future<AuthTicket> submitPassword({
    required String userName,
    required String password,
    required int lcid,
  }) async {
    onPassword?.call();
    return const AuthTicket(step: NeptunAuthStep.needsOtp);
  }

  @override
  Future<AuthTicket> submitOtp({
    required String userName,
    required String password,
    required int lcid,
    required String otp,
  }) async {
    return AuthTicket(
      step: NeptunAuthStep.authenticated,
      accessToken: 'debug-jwt',
      neptunCode: userName.toUpperCase(),
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
}
