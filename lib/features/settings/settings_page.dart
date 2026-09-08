import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';

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
                KarminCircleButton(
                  onPressed: () => context.pop(),
                  icon: KarminIcons.chevronLeft,
                  size: 36,
                  tooltip: 'Back',
                ),
                const SizedBox(width: 12),
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
                  variant: KarminCardVariant.elevated,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              KarminColors.carmine.withValues(alpha: 0.45),
                              KarminColors.navy,
                            ],
                          ),
                          border: Border.all(
                            color: KarminColors.carmine.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'A',
                          style: KarminTypography.title(fontSize: 20),
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
                            const SizedBox(height: 4),
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
                      Icon(
                        KarminIcons.verified,
                        size: 18,
                        color: KarminColors.steel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KarminSpacing.lg),
                KarminListRow(
                  leading: _SettingsIcon(KarminIcons.language),
                  title: l10n.settingsLanguage,
                  trailing: Text(l10n.settingsLanguageValue),
                  outlined: true,
                ),
                const SizedBox(height: KarminSpacing.sm),
                KarminListRow(
                  leading: _SettingsIcon(KarminIcons.faceId),
                  title: l10n.settingsFaceId,
                  trailing: Text(l10n.settingsOn),
                  outlined: true,
                ),
                const SizedBox(height: KarminSpacing.sm),
                KarminListRow(
                  leading: _SettingsIcon(KarminIcons.lock),
                  title: l10n.settingsPin,
                  trailing: Text(l10n.settingsChange),
                  outlined: true,
                ),
                const SizedBox(height: KarminSpacing.sm),
                KarminListRow(
                  leading: _SettingsIcon(KarminIcons.bell),
                  title: l10n.settingsNotifications,
                  trailing: Text(l10n.settingsNotificationsValue),
                  outlined: true,
                ),
                const SizedBox(height: KarminSpacing.xl),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    KarminIcons.logout,
                    size: 16,
                    color: KarminColors.carmineBright,
                  ),
                  label: Text(
                    l10n.settingsSignOut,
                    style: KarminTypography.body(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: KarminColors.carmineBright,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: KarminColors.navy,
        border: Border.all(color: KarminColors.hairline),
      ),
      child: Icon(icon, size: 15, color: KarminColors.steel),
    );
  }
}
