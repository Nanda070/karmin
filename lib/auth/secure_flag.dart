import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Best-effort FLAG_SECURE on Android (`karmin/secure_flag`). No-ops on
/// web/desktop or if the native channel is missing.
abstract final class SecureFlag {
  static const _channel = MethodChannel('karmin/secure_flag');

  static Future<void> setEnabled(bool enabled) async {
    if (kIsWeb) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setSecure', enabled);
    } on MissingPluginException {
      // Expected on web and until MainActivity wires the channel.
    } on PlatformException {
      // Do not fail the auth UI if the flag cannot be set.
    }
  }
}
