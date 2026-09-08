import 'dart:async';

import 'package:local_auth/local_auth.dart';

const _probeTimeout = Duration(seconds: 2);
const _authTimeout = Duration(seconds: 25);

/// Thin wrapper around [LocalAuthentication] for Stage 1 Unlock.
///
/// Prefer `biometricOnly` first; fall back to app-owned PIN UI on failure.
class LocalAuthProbe {
  LocalAuthProbe({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> canCheckBiometrics() =>
      _auth.canCheckBiometrics.timeout(_probeTimeout);

  Future<bool> isDeviceSupported() =>
      _auth.isDeviceSupported().timeout(_probeTimeout);

  Future<List<BiometricType>> availableBiometrics() =>
      _auth.getAvailableBiometrics().timeout(_probeTimeout);

  /// Returns whether hardware biometrics can be used for Unlock.
  Future<bool> isBiometricAvailable() async {
    try {
      final supported = await isDeviceSupported();
      if (!supported) {
        return false;
      }
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        return false;
      }
      final types = await availableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the OS biometric sheet. Does not fall back to device PIN/pattern.
  Future<bool> authenticateBiometricOnly({
    String reason = 'Unlock Karmin',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      ).timeout(_authTimeout);
    } catch (_) {
      return false;
    }
  }
}
