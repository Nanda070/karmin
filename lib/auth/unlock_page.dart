import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';
import 'package:karmin/auth/pin_hash.dart';
import 'package:karmin/auth/providers.dart';
import 'package:karmin/auth/widgets/karmin_mark.dart';
import 'package:karmin/auth/widgets/pin_pad.dart';
import 'package:karmin/auth/widgets/secure_auth_scaffold.dart';
import 'package:karmin/l10n/app_localizations.dart';

class UnlockPage extends ConsumerStatefulWidget {
  const UnlockPage({super.key});

  @override
  ConsumerState<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends ConsumerState<UnlockPage> {
  String _pin = '';
  var _bioTried = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBio());
  }

  Future<void> _tryBio() async {
    if (_bioTried) {
      return;
    }
    _bioTried = true;
    final auth = ref.read(authControllerProvider);
    if (!auth.bioEnabled || !auth.bioAvailable) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    await ref
        .read(authControllerProvider.notifier)
        .unlockWithBiometrics(reason: l10n.unlockBiometricReason);
  }

  Future<void> _onDigit(String digit) async {
    if (_pin.length >= PinHash.pinLength) {
      return;
    }
    setState(() => _pin += digit);
    if (_pin.length == PinHash.pinLength) {
      final ok =
          await ref.read(authControllerProvider.notifier).unlockWithPin(_pin);
      if (!ok && mounted) {
        setState(() => _pin = '');
      }
    }
  }

  void _backspace() {
    if (_pin.isEmpty) {
      return;
    }
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  String _subtitle(AppLocalizations l10n, AuthUnlockCopy auth) {
    if (auth.locked) {
      return l10n.unlockLocked(auth.lockSeconds);
    }
    if (auth.wrong) {
      return l10n.unlockWrongPin;
    }
    if (auth.bio) {
      return l10n.unlockSubtitle;
    }
    return l10n.unlockSubtitlePinOnly;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final locked = auth.pinIsLocked;
    final remaining = locked
        ? auth.pinLockedUntil!.difference(DateTime.now()).inSeconds.clamp(1, 999)
        : 0;
    final copy = AuthUnlockCopy(
      locked: locked,
      lockSeconds: remaining,
      wrong: auth.errorMessage == 'pin-wrong',
      bio: auth.bioEnabled && auth.bioAvailable,
    );

    return SecureAuthScaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            const AuthBadge(icon: KarminIcons.lock),
            const SizedBox(height: 16),
            Text(
              l10n.appTitle,
              style: KarminTypography.body(
                fontSize: 14,
                color: KarminColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.unlockTitle,
              style: KarminTypography.display(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              _subtitle(l10n, copy),
              textAlign: TextAlign.center,
              style: KarminTypography.body(
                fontSize: 13,
                color: copy.wrong || copy.locked
                    ? KarminColors.carmineBright
                    : KarminColors.muted,
              ),
            ),
            const SizedBox(height: 20),
            PinDots(length: _pin.length),
            const SizedBox(height: 20),
            PinKeypad(
              onDigit: _onDigit,
              onBackspace: _backspace,
              enabled: !locked,
            ),
            if (copy.bio)
              TextButton(
                onPressed: locked
                    ? null
                    : () => ref
                        .read(authControllerProvider.notifier)
                        .unlockWithBiometrics(
                          reason: l10n.unlockBiometricReason,
                        ),
                child: Text(l10n.unlockUseBiometrics),
              ),
            TextButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              child: Text(l10n.unlockSignOut),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthUnlockCopy {
  const AuthUnlockCopy({
    required this.locked,
    required this.lockSeconds,
    required this.wrong,
    required this.bio,
  });

  final bool locked;
  final int lockSeconds;
  final bool wrong;
  final bool bio;
}
