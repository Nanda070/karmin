import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_card.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart'
    show KarminCircleButton, KarminPageHeader, KarminStatChip;
import 'package:karmin/app/widgets/karmin_section_label.dart';
import 'package:karmin/app/widgets/karmin_status.dart';
import 'package:karmin/auth/providers.dart';
import 'package:karmin/data/providers.dart';
import 'package:karmin/data/student_repository.dart';
import 'package:karmin/l10n/app_localizations.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = KarminPalette.of(context);
    final now = DateTime.now();
    final dateLine = DateFormat('EEEE · MMM d').format(now);
    final auth = ref.watch(authControllerProvider);
    final async = ref.watch(studentSnapshotProvider);
    final snapshot = async.valueOrNull ?? StudentSnapshot.empty();
    final next = snapshot.nextClass(now);
    final exam = snapshot.nextExam(now);
    final todayEvents = snapshot.eventsOn(now);
    final code = auth.neptunCode ?? '';
    final initial = code.isNotEmpty ? code[0].toUpperCase() : 'K';
    final gpa = snapshot.dashboard.gpaLabel ?? '—';
    final unread = snapshot.unreadCount;
    final examLabel = exam == null
        ? '—'
        : DateFormat('E HH:mm').format(exam.start);
    final messagesLabel = unread > 0 ? l10n.inboxNewCount(unread) : '—';
    Future<void> refresh() =>
        ref.read(studentSnapshotProvider.notifier).refresh();

    return RefreshIndicator(
      color: palette.carmineBright,
      backgroundColor: palette.field,
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  tooltip: l10n.profilePlaceholder,
                  child: Text(
                    initial,
                    style: KarminTypography.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
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
                if (snapshot.errorMessage != null) ...[
                  KarminStatusBanner.fromSnapshot(
                    snapshot: snapshot,
                    l10n: l10n,
                    onRetry: refresh,
                  ),
                  const SizedBox(height: KarminSpacing.sm),
                ],
                const SizedBox(height: KarminSpacing.sm),
                KarminCard(
                  variant: KarminCardVariant.elevated,
                  accentBar: true,
                  accentBarColor: palette.carmineBright,
                  padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            KarminIcons.sparkles,
                            size: 12,
                            color: palette.accentText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.nextClassLabel,
                            style: KarminTypography.label(
                              fontSize: 11,
                              color: palette.accentText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        next?.title ?? l10n.todayEmptyNext,
                        style: KarminTypography.title(
                          fontSize: 20,
                          color: palette.text,
                        ),
                      ),
                      if (next != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (next.room != null) ...[
                              _MetaChip(
                                icon: KarminIcons.mapPin,
                                text: next.room!,
                              ),
                              const SizedBox(width: 8),
                            ],
                            _MetaChip(
                              icon: KarminIcons.clock,
                              text: _relative(l10n, now, next.start),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: KarminSpacing.md),
                Row(
                  children: [
                    KarminStatChip(
                      label: l10n.chipExam,
                      value: examLabel,
                      valueColor: palette.accentText,
                      icon: KarminIcons.exam,
                    ),
                    const SizedBox(width: KarminSpacing.sm),
                    KarminStatChip(
                      label: l10n.chipMessages,
                      value: messagesLabel,
                      icon: KarminIcons.mail,
                    ),
                    const SizedBox(width: KarminSpacing.sm),
                    KarminStatChip(
                      label: l10n.chipGpa,
                      value: gpa,
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
                if (todayEvents.isEmpty)
                  KarminEmptyState(
                    message: l10n.todayEmptySchedule,
                    icon: KarminIcons.calendar,
                  )
                else
                  for (var i = 0; i < todayEvents.length; i++) ...[
                    if (i > 0) const SizedBox(height: KarminSpacing.sm),
                    _ScheduleRow(
                      time: DateFormat('HH:mm').format(todayEvents[i].start),
                      title: todayEvents[i].title,
                      room: todayEvents[i].room ?? '—',
                      accent: todayEvents[i].isExam
                          ? palette.carmine
                          : palette.steel,
                      isExam: todayEvents[i].isExam,
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relative(AppLocalizations l10n, DateTime now, DateTime start) {
    final minutes = start.difference(now).inMinutes;
    if (minutes <= 0) {
      return l10n.relativeNow;
    }
    return l10n.relativeMinutes(minutes);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: palette.field.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.hairline.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: palette.muted),
          const SizedBox(width: 5),
          Text(
            text,
            style: KarminTypography.body(
              fontSize: 12,
              color: palette.muted,
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
    final palette = KarminPalette.of(context);
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
                    palette.carmine.withValues(alpha: 0.22),
                    palette.field,
                  ],
                ),
                border: Border.all(
                  color: palette.carmine.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(icon, size: 16, color: palette.accentText),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: KarminTypography.label(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: palette.text,
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
    final palette = KarminPalette.of(context);
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
                color: palette.text,
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
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isExam ? KarminIcons.exam : KarminIcons.mapPin,
                      size: 12,
                      color: palette.muted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        room,
                        style: KarminTypography.body(
                          fontSize: 12,
                          color: palette.muted,
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
            color: palette.muted.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}
