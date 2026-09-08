import 'package:local_auth/local_auth.dart';

/// Thin wrapper around [LocalAuthentication] for Stage 1 Unlock.
///
/// Prefer `biometricOnly` first; fall back to app-owned PIN UI on failure.
class LocalAuthProbe {
  LocalAuthProbe({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> canCheckBiometrics() => _auth.canCheckBiometrics;

  Future<bool> isDeviceSupported() => _auth.isDeviceSupported();

  Future<List<BiometricType>> availableBiometrics() =>
      _auth.getAvailableBiometrics();

  /// Returns whether hardware biometrics can be used for Unlock.
  Future<bool> isBiometricAvailable() async {
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
  }

  /// Prompts the OS biometric sheet. Does not fall back to device PIN/pattern.
  Future<bool> authenticateBiometricOnly({
    String reason = 'Unlock Karmin',
  }) {
    return _auth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }
}
