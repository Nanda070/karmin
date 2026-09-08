import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_client.dart';
import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';
import 'package:karmin/app/widgets/karmin_primary_button.dart';
import 'package:karmin/auth/auth_models.dart';
import 'package:karmin/auth/providers.dart';
import 'package:karmin/auth/widgets/auth_text_field.dart';
import 'package:karmin/auth/widgets/karmin_mark.dart';
import 'package:karmin/auth/widgets/secure_auth_scaffold.dart';
import 'package:karmin/l10n/app_localizations.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _otp = TextEditingController();
  Timer? _cooldownTick;

  @override
  void dispose() {
    _cooldownTick?.cancel();
    _otp.dispose();
    super.dispose();
  }

  void _scheduleCooldownTick() {
    _cooldownTick?.cancel();
    final remaining =
        ref.read(authControllerProvider).otpResendSecondsRemaining();
    if (remaining <= 0) {
      _cooldownTick = null;
      return;
    }
    _cooldownTick = Timer(const Duration(seconds: 1), () {
      if (!mounted) {
        return;
      }
      setState(() {});
      _scheduleCooldownTick();
    });
  }

  int get _lcid {
    final locale = Localizations.localeOf(context).languageCode;
    return NeptunClient.lcidForLanguageCode(locale);
  }

  Future<void> _submit() async {
    await ref.read(authControllerProvider.notifier).submitOtp(
          otp: _otp.text,
          lcid: _lcid,
        );
  }

  Future<void> _resend() async {
    await ref.read(authControllerProvider.notifier).resendEmailCode(
          lcid: _lcid,
        );
  }

  String _hint(AppLocalizations l10n, OtpChannel channel) {
    return switch (channel) {
      OtpChannel.email => l10n.otpSubtitleEmail,
      OtpChannel.authenticator => l10n.otpSubtitleAuthenticator,
      OtpChannel.unknown => l10n.otpSubtitleUnknown,
    };
  }

  String? _errorText(AppLocalizations l10n, String? error) {
    if (error == null) {
      return null;
    }
    if (error == const NeptunOtpException().message) {
      return l10n.otpError;
    }
    if (error == const NeptunAuthException().message) {
      return l10n.loginErrorBadCredentials;
    }
    if (error == const NeptunNetworkException().message) {
      return l10n.loginErrorNetwork;
    }
    if (error == const NeptunCaptchaException().message) {
      return l10n.loginErrorCaptcha;
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final error = _errorText(l10n, auth.errorMessage);
    final cooldown = auth.otpResendSecondsRemaining();
    final canResend = auth.otpResendReady() && !auth.busy;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous == null) {
        return;
      }
      if (next.otpResendNonce <= previous.otpResendNonce) {
        return;
      }
      _otp.clear();
      _scheduleCooldownTick();
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(l10n.otpResent),
          behavior: SnackBarBehavior.floating,
          backgroundColor: KarminColors.navy,
        ),
      );
    });

    return SecureAuthScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                AuthBadge(
                  icon: auth.otpChannel == OtpChannel.authenticator
                      ? KarminIcons.shield
                      : KarminIcons.mail,
                ),
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
                  l10n.otpTitle,
                  style: KarminTypography.display(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  _hint(l10n, auth.otpChannel),
                  textAlign: TextAlign.center,
                  style: KarminTypography.body(
                    fontSize: 13,
                    color: KarminColors.muted,
                  ),
                ),
                const SizedBox(height: 24),
                AuthTextField(
                  controller: _otp,
                  hint: l10n.otpCodeHint,
                  icon: KarminIcons.key,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: KarminTypography.body(
                      fontSize: 13,
                      color: KarminColors.carmineBright,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                KarminPrimaryButton(
                  label: l10n.otpConfirm,
                  busy: auth.busy,
                  onPressed: auth.busy ? null : _submit,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: canResend ? _resend : null,
                  child: Text(
                    cooldown > 0
                        ? l10n.otpResendWait(cooldown)
                        : l10n.otpResend,
                    style: KarminTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: canResend
                          ? KarminColors.carmineBright
                          : KarminColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
