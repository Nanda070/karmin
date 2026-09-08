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

class SetPinPage extends ConsumerStatefulWidget {
  const SetPinPage({super.key});

  @override
  ConsumerState<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends ConsumerState<SetPinPage> {
  String _first = '';
  String _current = '';
  var _confirming = false;
  var _mismatch = false;
  var _enableBio = true;

  void _onDigit(String digit) {
    if (_current.length >= PinHash.pinLength) {
      return;
    }
    setState(() {
      _current += digit;
      _mismatch = false;
    });
    if (_current.length == PinHash.pinLength) {
      _advance();
    }
  }

  void _backspace() {
    if (_current.isEmpty) {
      return;
    }
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  Future<void> _advance() async {
    if (!_confirming) {
      setState(() {
        _first = _current;
        _current = '';
        _confirming = true;
      });
      return;
    }
    if (_current != _first) {
      setState(() {
        _current = '';
        _first = '';
        _confirming = false;
        _mismatch = true;
      });
      return;
    }
    final auth = ref.read(authControllerProvider);
    await ref.read(authControllerProvider.notifier).setPin(
          _current,
          enableBio: _enableBio && auth.bioAvailable,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);

    return SecureAuthScaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
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
              _confirming ? l10n.setPinConfirmTitle : l10n.setPinTitle,
              style: KarminTypography.display(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              _mismatch
                  ? l10n.setPinMismatch
                  : (_confirming
                      ? l10n.setPinConfirmSubtitle
                      : l10n.setPinSubtitle),
              textAlign: TextAlign.center,
              style: KarminTypography.body(
                fontSize: 13,
                color: _mismatch
                    ? KarminColors.carmineBright
                    : KarminColors.muted,
              ),
            ),
            const SizedBox(height: 20),
            PinDots(length: _current.length),
            const SizedBox(height: 20),
            PinKeypad(onDigit: _onDigit, onBackspace: _backspace),
            if (auth.bioAvailable) ...[
              SwitchListTile.adaptive(
                value: _enableBio,
                onChanged: (value) => setState(() => _enableBio = value),
                title: Text(
                  l10n.setPinEnableBio,
                  style: KarminTypography.body(fontSize: 14),
                ),
                activeThumbColor: KarminColors.carmineBright,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
