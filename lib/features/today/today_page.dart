import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_card.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart'
    show KarminCircleButton, KarminPageHeader, KarminStatChip;
import 'package:karmin/app/widgets/karmin_section_label.dart';
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: KarminSpacing.sm),
              KarminCircleButton(
                onPressed: () => context.push('/settings'),
                bordered: true,
                tooltip: l10n.settingsTitle,
                icon: KarminIcons.settings,
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
                variant: KarminCardVariant.elevated,
                accentBar: true,
                accentBarColor: KarminColors.carmineBright,
                padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          KarminIcons.sparkles,
                          size: 12,
                          color: KarminColors.carmineBright,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.nextClassLabel,
                          style: KarminTypography.label(
                            fontSize: 11,
                            color: KarminColors.carmineBright,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.demoNextClassTitle,
                      style: KarminTypography.title(fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MetaChip(
                          icon: KarminIcons.mapPin,
                          text: 'D 3-510',
                        ),
                        const SizedBox(width: 8),
                        _MetaChip(
                          icon: KarminIcons.clock,
                          text: 'in 12 min',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KarminSpacing.md),
              Row(
                children: [
                  KarminStatChip(
                    label: l10n.chipExam,
                    value: l10n.demoExamTime,
                    valueColor: KarminColors.carmineBright,
                    icon: KarminIcons.exam,
                  ),
                  const SizedBox(width: KarminSpacing.sm),
                  KarminStatChip(
                    label: l10n.chipMessages,
                    value: l10n.demoMessagesNew,
                    icon: KarminIcons.mail,
                  ),
                  const SizedBox(width: KarminSpacing.sm),
                  KarminStatChip(
                    label: l10n.chipGpa,
                    value: l10n.demoGpa,
                    icon: KarminIcons.trending,
                  ),
                ],
              ),
              const SizedBox(height: KarminSpacing.xl),
              KarminSectionLabel(l10n.todayQuickActions),
              const SizedBox(height: KarminSpacing.sm),
              Row(
                children: [
                  _QuickAction(
                    icon: KarminIcons.calendarPlus,
                    label: l10n.todayActionSchedule,
                    onTap: () => context.go('/calendar'),
                  ),
                  const SizedBox(width: KarminSpacing.sm),
                  _QuickAction(
                    icon: KarminIcons.book,
                    label: l10n.todayActionSubjects,
                    onTap: () => context.go('/study'),
                  ),
                  const SizedBox(width: KarminSpacing.sm),
                  _QuickAction(
                    icon: KarminIcons.message,
                    label: l10n.todayActionInbox,
                    onTap: () => context.go('/inbox'),
                  ),
                ],
              ),
              const SizedBox(height: KarminSpacing.xl),
              KarminSectionLabel(l10n.todaySchedule),
              const SizedBox(height: KarminSpacing.sm),
              _ScheduleRow(
                time: '08:00',
                title: l10n.demoSubjectAnalysis,
                room: l10n.demoEventAnalysisRoom,
                accent: KarminColors.steel,
              ),
              const SizedBox(height: KarminSpacing.sm),
              _ScheduleRow(
                time: '10:15',
                title: l10n.demoEventProgrammingTitle,
                room: l10n.demoEventProgrammingRoom,
                accent: KarminColors.steel,
              ),
              const SizedBox(height: KarminSpacing.sm),
              _ScheduleRow(
                time: '10:00',
                title: l10n.demoEventExamTitle,
                room: l10n.demoEventExamRoom,
                accent: KarminColors.carmine,
                isExam: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: KarminColors.navy.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KarminColors.hairline.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: KarminColors.muted),
          const SizedBox(width: 5),
          Text(
            text,
            style: KarminTypography.body(
              fontSize: 12,
              color: KarminColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: KarminCard(
        onTap: onTap,
        radius: KarminRadii.md,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    KarminColors.carmine.withValues(alpha: 0.22),
                    KarminColors.navy,
                  ],
                ),
                border: Border.all(
                  color: KarminColors.carmine.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(icon, size: 16, color: KarminColors.carmineBright),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: KarminTypography.label(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: KarminColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.time,
    required this.title,
    required this.room,
    required this.accent,
    this.isExam = false,
  });

  final String time;
  final String title;
  final String room;
  final Color accent;
  final bool isExam;

  @override
  Widget build(BuildContext context) {
    return KarminCard(
      accentBar: true,
      accentBarColor: accent,
      radius: KarminRadii.md,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              time,
              style: KarminTypography.label(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KarminColors.text,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KarminTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isExam ? KarminIcons.exam : KarminIcons.mapPin,
                      size: 12,
                      color: KarminColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        room,
                        style: KarminTypography.body(
                          fontSize: 12,
                          color: KarminColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            KarminIcons.chevronRight,
            size: 16,
            color: KarminColors.muted.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}
