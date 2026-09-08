import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:karmin/api/neptun_auth.dart';
import 'package:karmin/api/neptun_client.dart';
import 'package:karmin/auth/auth_controller.dart';
import 'package:karmin/auth/auth_models.dart';
import 'package:karmin/auth/local_auth_probe.dart';
import 'package:karmin/auth/prefs.dart';
import 'package:karmin/auth/secure_store.dart';

final secureStoreProvider = Provider<SecureStore>((ref) {
  return KeystoreSecureStore();
});

final prefsStoreProvider = Provider<PrefsStore>((ref) {
  return SharedPrefsStore();
});

final neptunClientProvider = Provider<NeptunClient>((ref) {
  return NeptunClient();
});

final debugAuthFlagProvider = Provider<bool>((ref) => useDebugAuth());

final neptunAuthApiProvider = Provider<NeptunAuthApi>((ref) {
  if (ref.watch(debugAuthFlagProvider)) {
    return DebugNeptunAuth();
  }
  return LiveNeptunAuth(ref.watch(neptunClientProvider));
});

final localAuthProbeProvider = Provider<LocalAuthProbe>((ref) {
  return LocalAuthProbe();
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    store: ref.watch(secureStoreProvider),
    prefs: ref.watch(prefsStoreProvider),
    authApi: ref.watch(neptunAuthApiProvider),
    client: ref.watch(neptunClientProvider),
    localAuth: ref.watch(localAuthProbeProvider),
    usingDebugAuth: ref.watch(debugAuthFlagProvider),
  );
});
