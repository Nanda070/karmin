import 'package:karmin/auth/auth_models.dart';

const kAuthPaths = {
  '/boot',
  '/disclaimer',
  '/login',
  '/verify',
  '/set-pin',
  '/unlock',
};

/// Pure go_router redirect. Null means stay on [path].
String? authRedirect(AuthState auth, String path) {
  if (!auth.hydrated) {
    return path == '/boot' ? null : '/boot';
  }

  if (!auth.disclaimerAccepted) {
    return path == '/disclaimer' ? null : '/disclaimer';
  }

  if (!auth.hasCredentials && auth.neptunStep == NeptunAuthStep.needsPassword) {
    return path == '/login' ? null : '/login';
  }

  if (auth.hasPin && !auth.unlocked) {
    return path == '/unlock' ? null : '/unlock';
  }

  if (auth.neptunStep == NeptunAuthStep.needsOtp) {
    return path == '/verify' ? null : '/verify';
  }

  if (auth.neptunStep == NeptunAuthStep.needsPassword) {
    if (auth.hasCredentials) {
      return path == '/unlock' || path == '/login' || path == '/boot'
          ? (path == '/boot' ? '/unlock' : null)
          : '/unlock';
    }
    return path == '/login' ? null : '/login';
  }

  if (!auth.hasPin) {
    return path == '/set-pin' ? null : '/set-pin';
  }

  if (kAuthPaths.contains(path)) {
    return '/today';
  }

  return null;
}
