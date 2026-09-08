import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_card.dart';
import 'package:karmin/app/widgets/karmin_list_row.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart';
import 'package:karmin/l10n/app_localizations.dart';

/// Settings shell with Stage 0 demo profile (matches Figma).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return KarminScaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: KarminSpacing.xxxl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KarminSpacing.pageX,
              KarminSpacing.md,
              KarminSpacing.pageX,
              KarminSpacing.sm,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '‹',
                      style: KarminTypography.display(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Text(
                  l10n.settingsTitle,
                  style: KarminTypography.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KarminSpacing.pageX),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KarminCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: KarminColors.navy,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          'A',
                          style: KarminTypography.body(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: KarminSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.demoProfileName,
                              style: KarminTypography.title(fontSize: 16),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              l10n.demoProfileCode,
                              style: KarminTypography.body(
                                fontSize: 12,
                                color: KarminColors.muted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.demoProfileProgram,
                              style: KarminTypography.body(
                                fontSize: 12,
                                color: KarminColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KarminSpacing.lg),
                KarminListRow(
                  title: l10n.settingsLanguage,
                  trailing: Text(l10n.settingsLanguageValue),
                ),
                const SizedBox(height: KarminSpacing.sm),
                KarminListRow(
                  title: l10n.settingsFaceId,
                  trailing: Text(l10n.settingsOn),
                ),
                const SizedBox(height: KarminSpacing.sm),
                KarminListRow(
                  title: l10n.settingsPin,
                  trailing: Text(l10n.settingsChange),
                ),
                const SizedBox(height: KarminSpacing.sm),
                KarminListRow(
                  title: l10n.settingsNotifications,
                  trailing: Text(l10n.settingsNotificationsValue),
                ),
                const SizedBox(height: KarminSpacing.xl),
                TextButton(
                  onPressed: () {},
                  child: Text(l10n.settingsSignOut),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
