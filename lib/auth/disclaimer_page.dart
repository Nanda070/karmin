import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_primary_button.dart';
import 'package:karmin/auth/providers.dart';
import 'package:karmin/auth/widgets/karmin_mark.dart';
import 'package:karmin/auth/widgets/secure_auth_scaffold.dart';
import 'package:karmin/l10n/app_localizations.dart';

class DisclaimerPage extends ConsumerWidget {
  const DisclaimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return SecureAuthScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        children: [
          const Center(child: KarminMark()),
          const SizedBox(height: 16),
          Text(
            l10n.disclaimerTitle,
            textAlign: TextAlign.center,
            style: KarminTypography.display(fontSize: 28),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.disclaimerBody,
            style: KarminTypography.body(
              fontSize: 14,
              color: KarminColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse('https://neptun.elte.hu/'),
              mode: LaunchMode.externalApplication,
            ),
            child: Text(l10n.disclaimerOfficialNeptun),
          ),
          const SizedBox(height: 12),
          KarminPrimaryButton(
            label: l10n.disclaimerUnderstand,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).acceptDisclaimer(),
          ),
        ],
      ),
    );
  }
}
