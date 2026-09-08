import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_card.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart'
    show KarminCircleButton, KarminPageHeader, KarminStatChip;
import 'package:karmin/l10n/app_localizations.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final dateLine = DateFormat('EEEE · MMM d').format(now);

    return ListView(
        padding: const EdgeInsets.only(bottom: KarminSpacing.xxl),
        children: [
          KarminPageHeader(
            title: l10n.tabToday,
            subtitle: dateLine,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                KarminCircleButton(
                  onPressed: () => context.push('/settings'),
                  child: Text(
                    'A',
                    style: KarminTypography.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: KarminSpacing.sm),
                KarminCircleButton(
                  onPressed: () => context.push('/settings'),
                  bordered: true,
                  tooltip: l10n.settingsTitle,
                  icon: Icons.settings_outlined,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KarminSpacing.pageX),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: KarminSpacing.sm),
                KarminCard(
                  accentBar: true,
                  accentBarColor: KarminColors.steel,
                  padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.nextClassLabel,
                        style: KarminTypography.label(fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.demoNextClassTitle,
                        style: KarminTypography.title(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.demoNextClassMeta,
                        style: KarminTypography.body(
                          fontSize: 13,
                          color: KarminColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KarminSpacing.sm),
                Row(
                  children: [
                    KarminStatChip(
                      label: l10n.chipExam,
                      value: l10n.demoExamTime,
                      valueColor: KarminColors.carmine,
                    ),
                    const SizedBox(width: KarminSpacing.sm),
                    KarminStatChip(
                      label: l10n.chipMessages,
                      value: l10n.demoMessagesNew,
                    ),
                    const SizedBox(width: KarminSpacing.sm),
                    KarminStatChip(
                      label: l10n.chipGpa,
                      value: l10n.demoGpa,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
    );
  }
}
