import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore_for_file: prefer_initializing_formals

import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_auth.dart';
import 'package:karmin/api/neptun_client.dart';
import 'package:karmin/auth/auth_models.dart';
import 'package:karmin/auth/local_auth_probe.dart';
import 'package:karmin/auth/pin_hash.dart';
import 'package:karmin/auth/prefs.dart';
import 'package:karmin/auth/secure_storage_keys.dart';
import 'package:karmin/auth/secure_store.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required SecureStore store,
    required PrefsStore prefs,
    required NeptunAuthApi authApi,
    required NeptunClient client,
    required LocalAuthProbe localAuth,
    required bool usingDebugAuth,
    bool hydrateOnStart = true,
    this.otpResendCooldown = const Duration(seconds: 30),
    this.hydrateTimeout = const Duration(seconds: 5),
    DateTime Function()? clock,
  })  : _store = store,
        _prefs = prefs,
        _authApi = authApi,
        _client = client,
        _localAuth = localAuth,
        _now = clock ?? DateTime.now,
        super(AuthState.loading(usingDebugAuth: usingDebugAuth)) {
    _client.onUnauthorized = onUnauthorized;
    if (hydrateOnStart) {
      unawaited(hydrate());
    }
  }

  final SecureStore _store;
  final PrefsStore _prefs;
  final NeptunAuthApi _authApi;
  final NeptunClient _client;
  final LocalAuthProbe _localAuth;
  final DateTime Function() _now;
  final Duration otpResendCooldown;
  final Duration hydrateTimeout;

  String? _pendingUser;
  String? _pendingPassword;
  int _pinLockouts = 0;
  DateTime? _backgroundedAt;

  static const firstLock = Duration(seconds: 30);
  static const nextLock = Duration(minutes: 5);
  static const maxPinAttempts = 5;

  Future<void> hydrate() async {
    final deadline = DateTime.now().add(hydrateTimeout);

    Future<T> timed<T>(Future<T> future, T fallback) async {
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        return fallback;
      }
      try {
        return await future.timeout(remaining);
      } catch (_) {
        return fallback;
      }
    }

    final disclaimer = await timed(_prefs.getDisclaimerAccepted(), false);
    final code = await timed(_store.read(SecureStorageKeys.neptunCode), null);
    final password =
        await timed(_store.read(SecureStorageKeys.neptunPassword), null);
    final pinHash = await timed(_store.read(SecureStorageKeys.pinHash), null);
    final bioFlag = await timed(_store.read(SecureStorageKeys.bioEnabled), null);
    final bioAvailable = await timed(_localAuth.isBiometricAvailable(), false);

    final hasCredentials =
        (code?.isNotEmpty ?? false) && (password?.isNotEmpty ?? false);
    final hasPin = pinHash != null && pinHash.isNotEmpty;

    state = state.copyWith(
      hydrated: true,
      disclaimerAccepted: disclaimer,
      hasCredentials: hasCredentials,
      hasPin: hasPin,
      unlocked: false,
      neptunStep: _client.hasJwt
          ? NeptunAuthStep.authenticated
          : NeptunAuthStep.needsPassword,
      bioEnabled: bioFlag == '1',
      bioAvailable: bioAvailable,
      neptunCode: code,
      clearError: true,
    );
  }

  Future<void> acceptDisclaimer() async {
    await _prefs.setDisclaimerAccepted(true);
    state = state.copyWith(disclaimerAccepted: true, clearError: true);
  }

  Future<void> login({
    required String userName,
    required String password,
    required int lcid,
  }) async {
    final code = userName.trim();
    if (code.isEmpty || password.isEmpty) {
      state = state.copyWith(errorMessage: 'empty');
      return;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      final ticket = await _authApi.submitPassword(
        userName: code,
        password: password,
        lcid: lcid,
      );
      await _applyTicket(
        ticket,
        userName: code,
        password: password,
      );
    } on NeptunException catch (error) {
      state = state.copyWith(busy: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        busy: false,
        errorMessage: const NeptunNetworkException().message,
      );
    }
  }

  Future<void> submitOtp({
    required String otp,
    required int lcid,
  }) async {
    final user = _pendingUser;
    final password = _pendingPassword;
    if (user == null || password == null) {
      if (state.hasCredentials) {
        await _loadPendingFromStore();
      }
    }
    final resolvedUser = _pendingUser;
    final resolvedPassword = _pendingPassword;
    if (resolvedUser == null || resolvedPassword == null) {
      state = state.copyWith(
        neptunStep: NeptunAuthStep.needsPassword,
        errorMessage: const NeptunAuthException().message,
      );
      return;
    }

    state = state.copyWith(busy: true, clearError: true);
    try {
      final ticket = await _authApi.submitOtp(
        userName: resolvedUser,
        password: resolvedPassword,
        lcid: lcid,
        otp: otp,
      );
      if (ticket.step == NeptunAuthStep.needsOtp) {
        state = state.copyWith(
          busy: false,
          errorMessage: const NeptunOtpException().message,
        );
        return;
      }
      await _applyTicket(
        ticket,
        userName: resolvedUser,
        password: resolvedPassword,
      );
    } on NeptunException catch (error) {
      state = state.copyWith(busy: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        busy: false,
        errorMessage: const NeptunOtpException().message,
      );
    }
  }

  Future<void> resendEmailCode({required int lcid}) async {
    if (state.busy) {
      return;
    }
    if (!state.otpResendReady(_now())) {
      return;
    }

    if (_pendingUser == null || _pendingPassword == null) {
      await _loadPendingFromStore();
    }
    final user = _pendingUser;
    final password = _pendingPassword;
    if (user == null || password == null) {
      state = state.copyWith(
        neptunStep: NeptunAuthStep.needsOtp,
        errorMessage: const NeptunAuthException().message,
      );
      return;
    }

    state = state.copyWith(busy: true, clearError: true);
    try {
      final ticket = await _authApi.resendEmailCode(
        userName: user,
        password: password,
        lcid: lcid,
      );
      if (ticket.step == NeptunAuthStep.needsOtp) {
        _pendingUser = user;
        _pendingPassword = password;
        state = state.copyWith(
          busy: false,
          neptunStep: NeptunAuthStep.needsOtp,
          otpChannel: ticket.otpChannel,
          otpResendAvailableAt: _now().add(otpResendCooldown),
          otpResendNonce: state.otpResendNonce + 1,
          clearError: true,
        );
        return;
      }
      if (ticket.hasJwt) {
        await _applyTicket(ticket, userName: user, password: password);
        return;
      }
      state = state.copyWith(
        busy: false,
        neptunStep: NeptunAuthStep.needsOtp,
        errorMessage: const NeptunAuthException().message,
      );
    } on NeptunException catch (error) {
      state = state.copyWith(
        busy: false,
        neptunStep: NeptunAuthStep.needsOtp,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        busy: false,
        neptunStep: NeptunAuthStep.needsOtp,
        errorMessage: const NeptunNetworkException().message,
      );
    }
  }

  Future<void> setPin(String pin, {required bool enableBio}) async {
    if (!PinHash.isValidPin(pin)) {
      state = state.copyWith(errorMessage: 'pin-invalid');
      return;
    }
    final salt = PinHash.generateSalt();
    final hash = PinHash.hash(pin, salt);
    await _store.write(SecureStorageKeys.pinSalt, PinHash.encodeSalt(salt));
    await _store.write(SecureStorageKeys.pinHash, hash);
    await _store.write(
      SecureStorageKeys.bioEnabled,
      enableBio && state.bioAvailable ? '1' : '0',
    );
    state = state.copyWith(
      hasPin: true,
      unlocked: true,
      bioEnabled: enableBio && state.bioAvailable,
      clearError: true,
    );
  }

  Future<bool> unlockWithPin(String pin) async {
    if (state.pinIsLocked) {
      return false;
    }
    final hash = await _store.read(SecureStorageKeys.pinHash);
    final saltEncoded = await _store.read(SecureStorageKeys.pinSalt);
    if (hash == null || saltEncoded == null) {
      state = state.copyWith(errorMessage: 'pin-missing');
      return false;
    }
    final salt = PinHash.decodeSalt(saltEncoded);
    if (!PinHash.matches(pin, salt, hash)) {
      _registerPinFailure();
      return false;
    }
    _pinLockouts = 0;
    state = state.copyWith(
      unlocked: true,
      pinAttempts: 0,
      clearPinLock: true,
      clearError: true,
    );
    await establishNeptunSessionIfNeeded();
    return true;
  }

  Future<bool> unlockWithBiometrics({String reason = 'Unlock Karmin'}) async {
    if (!state.bioEnabled || !state.bioAvailable) {
      return false;
    }
    try {
      final ok = await _localAuth.authenticateBiometricOnly(reason: reason);
      if (!ok) {
        return false;
      }
      state = state.copyWith(unlocked: true, clearError: true);
      await establishNeptunSessionIfNeeded();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> establishNeptunSessionIfNeeded({int lcid = 1033}) async {
    if (_client.hasJwt) {
      state = state.copyWith(neptunStep: NeptunAuthStep.authenticated);
      return;
    }
    if (!state.hasCredentials) {
      return;
    }
    await _loadPendingFromStore();
    final user = _pendingUser;
    final password = _pendingPassword;
    if (user == null || password == null) {
      return;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      final ticket = await _authApi.submitPassword(
        userName: user,
        password: password,
        lcid: lcid,
      );
      await _applyTicket(ticket, userName: user, password: password);
    } on NeptunException catch (error) {
      state = state.copyWith(busy: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        busy: false,
        errorMessage: const NeptunNetworkException().message,
      );
    }
  }

  void lockLocally() {
    if (!state.hasPin) {
      return;
    }
    if (!state.unlocked) {
      return;
    }
    state = state.copyWith(unlocked: false, clearError: true);
  }

  void onAppPaused() {
    _backgroundedAt = DateTime.now();
  }

  void onAppResumed() {
    if (_backgroundedAt != null) {
      lockLocally();
    }
    _backgroundedAt = null;
  }

  void onUnauthorized() {
    _client.clearSession();
    if (state.unlocked && state.hasCredentials) {
      state = state.copyWith(neptunStep: NeptunAuthStep.needsPassword);
      unawaited(establishNeptunSessionIfNeeded());
    } else {
      state = state.copyWith(neptunStep: NeptunAuthStep.needsPassword);
    }
  }

  Future<void> signOut() async {
    await _store.clearCredentials();
    _client.clearSession();
    _pendingUser = null;
    _pendingPassword = null;
    _pinLockouts = 0;
    state = state.copyWith(
      hasCredentials: false,
      hasPin: false,
      unlocked: false,
      neptunStep: NeptunAuthStep.needsPassword,
      bioEnabled: false,
      clearNeptunCode: true,
      otpChannel: OtpChannel.unknown,
      pinAttempts: 0,
      clearPinLock: true,
      clearOtpResend: true,
      otpResendNonce: 0,
      clearError: true,
      busy: false,
    );
  }

  void beginChangePin() {
    if (!state.hasPin || !state.unlocked) {
      return;
    }
    state = state.copyWith(hasPin: false);
  }

  Future<void> setBioEnabled(bool enabled) async {
    await _store.write(SecureStorageKeys.bioEnabled, enabled ? '1' : '0');
    state = state.copyWith(bioEnabled: enabled && state.bioAvailable);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @visibleForTesting
  void debugSetState(AuthState next) {
    state = next;
  }

  Future<void> _applyTicket(
    AuthTicket ticket, {
    required String userName,
    required String password,
  }) async {
    if (ticket.step == NeptunAuthStep.needsOtp) {
      _pendingUser = userName;
      _pendingPassword = password;
      state = state.copyWith(
        busy: false,
        neptunStep: NeptunAuthStep.needsOtp,
        otpChannel: ticket.otpChannel,
        clearError: true,
      );
      return;
    }

    if (!ticket.hasJwt) {
      state = state.copyWith(
        busy: false,
        errorMessage: const NeptunAuthException().message,
      );
      return;
    }

    _client.setAccessToken(ticket.accessToken);
    await _store.write(SecureStorageKeys.neptunCode, userName);
    await _store.write(SecureStorageKeys.neptunPassword, password);
    _pendingUser = null;
    _pendingPassword = null;
    state = state.copyWith(
      busy: false,
      hasCredentials: true,
      unlocked: true,
      neptunStep: NeptunAuthStep.authenticated,
      neptunCode: ticket.neptunCode ?? userName,
      clearError: true,
    );
  }

  Future<void> _loadPendingFromStore() async {
    _pendingUser = await _store.read(SecureStorageKeys.neptunCode);
    _pendingPassword = await _store.read(SecureStorageKeys.neptunPassword);
  }

  void _registerPinFailure() {
    final attempts = state.pinAttempts + 1;
    if (attempts >= maxPinAttempts) {
      _pinLockouts += 1;
      final duration = _pinLockouts == 1 ? firstLock : nextLock;
      state = state.copyWith(
        pinAttempts: 0,
        pinLockedUntil: DateTime.now().add(duration),
        errorMessage: 'pin-locked',
      );
      return;
    }
    state = state.copyWith(
      pinAttempts: attempts,
      errorMessage: 'pin-wrong',
    );
  }
}
