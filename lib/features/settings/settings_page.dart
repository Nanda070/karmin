import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/theme_mode_controller.dart';
import 'package:karmin/app/widgets/karmin_card.dart';
import 'package:karmin/app/widgets/karmin_list_row.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart';
import 'package:karmin/auth/providers.dart';
import 'package:karmin/data/providers.dart';
import 'package:karmin/data/student_repository.dart';
import 'package:karmin/l10n/app_localizations.dart';

/// Settings with profile from the student snapshot (debug fixtures or UserInfo).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  String _themeLabel(AppLocalizations l10n, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => l10n.settingsThemeLight,
      ThemeMode.system => l10n.settingsThemeSystem,
      ThemeMode.dark => l10n.settingsThemeDark,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final snapshot =
        ref.watch(studentSnapshotProvider).valueOrNull ?? StudentSnapshot.empty();
    final profile = snapshot.profile;
    final code = profile.neptunCode ?? auth.neptunCode ?? l10n.demoProfileCode;
    final name = (profile.displayName != null && profile.displayName!.isNotEmpty)
        ? profile.displayName!
        : l10n.profilePlaceholder;
    final training = (profile.training != null && profile.training!.isNotEmpty)
        ? profile.training!
        : l10n.profileSubtitle;
    final initial = profile.initial(
      fallback: code.isNotEmpty ? code[0].toUpperCase() : 'K',
    );

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
                          initial,
                          style: KarminTypography.title(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: KarminSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: KarminTypography.title(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              code,
                              style: KarminTypography.body(
                                fontSize: 12,
                                color: KarminColors.muted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              training,
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
                  leading: _SettingsIcon(KarminIcons.palette),
                  title: l10n.settingsTheme,
                  subtitle: l10n.settingsThemeHint,
                  trailing: Text(_themeLabel(l10n, themeMode)),
                  outlined: true,
                  onTap: () =>
                      ref.read(themeModeControllerProvider.notifier).cycle(),
                ),
                const SizedBox(height: KarminSpacing.sm),
                KarminListRow(
                  leading: _SettingsIcon(KarminIcons.faceId),
                  title: l10n.settingsFaceId,
                  trailing: Text(
                    !auth.bioAvailable
                        ? l10n.settingsFaceIdUnavailable
                        : (auth.bioEnabled ? l10n.settingsOn : l10n.settingsOff),
                  ),
                  outlined: true,
                  onTap: !auth.bioAvailable
                      ? null
                      : () => ref
                          .read(authControllerProvider.notifier)
                          .setBioEnabled(!auth.bioEnabled),
                ),
                const SizedBox(height: KarminSpacing.sm),
                KarminListRow(
                  leading: _SettingsIcon(KarminIcons.lock),
                  title: l10n.settingsPin,
                  trailing: Text(l10n.settingsChange),
                  outlined: true,
                  onTap: () =>
                      ref.read(authControllerProvider.notifier).beginChangePin(),
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
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
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
