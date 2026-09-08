import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_client.dart';
import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';
import 'package:karmin/app/widgets/karmin_primary_button.dart';
import 'package:karmin/auth/providers.dart';
import 'package:karmin/auth/widgets/auth_text_field.dart';
import 'package:karmin/auth/widgets/karmin_mark.dart';
import 'package:karmin/auth/widgets/secure_auth_scaffold.dart';
import 'package:karmin/l10n/app_localizations.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  var _obscure = true;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final locale = Localizations.localeOf(context).languageCode;
    await ref.read(authControllerProvider.notifier).login(
          userName: _code.text,
          password: _password.text,
          lcid: NeptunClient.lcidForLanguageCode(locale),
        );
  }

  String? _errorText(AppLocalizations l10n, String? error) {
    if (error == null) {
      return null;
    }
    if (error == 'empty') {
      return l10n.loginErrorEmpty;
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
    final captcha = auth.errorMessage == const NeptunCaptchaException().message;

    return SecureAuthScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                const KarminMark(),
                const SizedBox(height: 8),
                Text(
                  l10n.appTitle,
                  style: KarminTypography.display(fontSize: 34),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.loginSubtitle,
                  style: KarminTypography.body(
                    fontSize: 13,
                    color: KarminColors.muted,
                  ),
                ),
                if (auth.usingDebugAuth) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.loginDebugBanner,
                    textAlign: TextAlign.center,
                    style: KarminTypography.body(
                      fontSize: 12,
                      color: KarminColors.carmineBright,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _code,
                  hint: l10n.loginNeptunCode,
                  icon: KarminIcons.person,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                ),
                const SizedBox(height: 10),
                AuthTextField(
                  controller: _password,
                  hint: l10n.loginPassword,
                  icon: KarminIcons.lock,
                  obscure: _obscure,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  autofillHints: const [AutofillHints.password],
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
                if (captcha) ...[
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse('https://neptun.elte.hu/'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(l10n.loginOpenWebsite),
                  ),
                ],
                const SizedBox(height: 20),
                KarminPrimaryButton(
                  label: l10n.loginSignIn,
                  busy: auth.busy,
                  onPressed: auth.busy ? null : _submit,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.loginKeystoreHint,
                  textAlign: TextAlign.center,
                  style: KarminTypography.body(
                    fontSize: 12,
                    color: KarminColors.muted,
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
