import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/dtos/exam_offer.dart';
import 'package:karmin/api/dtos/taken_subject.dart';
import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_card.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';
import 'package:karmin/app/widgets/karmin_primary_button.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart' show KarminPageHeader;
import 'package:karmin/app/widgets/karmin_section_label.dart';
import 'package:karmin/app/widgets/karmin_status.dart';
import 'package:karmin/data/providers.dart';
import 'package:karmin/data/student_repository.dart';
import 'package:karmin/l10n/app_localizations.dart';

class StudyPage extends ConsumerWidget {
  const StudyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = KarminPalette.of(context);
    final async = ref.watch(studentSnapshotProvider);
    final snapshot = async.valueOrNull ?? StudentSnapshot.empty();
    final gpa = snapshot.dashboard.gpaLabel ?? '—';
    final credits = snapshot.dashboard.creditsLabel ?? '—';
    final exam = snapshot.signupExam;
    final calendarExam = snapshot.nextExam(DateTime.now());
    final examTitle = exam?.subjectName ?? calendarExam?.title;
    final examWhen = exam?.start ?? calendarExam?.start;
    final examLine = examTitle == null
        ? '—'
        : examWhen == null
            ? examTitle
            : '$examTitle · ${DateFormat('E HH:mm').format(examWhen)}';
    final canSignUp = exam != null && exam.canSignUp && exam.id.isNotEmpty;
    final alreadySigned = exam?.signedUp == true;

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
            title: l10n.tabStudy,
            trailing: Icon(
              KarminIcons.study,
              size: 20,
              color: palette.muted,
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
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: KarminIcons.trending,
                        label: l10n.chipGpa,
                        value: gpa,
                      ),
                    ),
                    const SizedBox(width: KarminSpacing.sm),
                    Expanded(
                      child: _StatCard(
                        icon: KarminIcons.layers,
                        label: l10n.studyCredits,
                        value: credits,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KarminSpacing.xl),
                KarminSectionLabel(l10n.studySubjects),
                const SizedBox(height: KarminSpacing.sm),
                if (snapshot.subjects.isEmpty)
                  KarminEmptyState(
                    message: l10n.studyEmpty,
                    icon: KarminIcons.book,
                  )
                else
                  for (var i = 0; i < snapshot.subjects.length; i++) ...[
                    if (i > 0) const SizedBox(height: KarminSpacing.sm),
                    _SubjectRow(
                      subject: snapshot.subjects[i],
                      onTap: () => context.push(
                        '/study/${Uri.encodeComponent(snapshot.subjects[i].id)}',
                      ),
                    ),
                  ],
                const SizedBox(height: KarminSpacing.lg),
                KarminCard(
                  variant: KarminCardVariant.elevated,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: palette.carmine.withValues(alpha: 0.18),
                              border: Border.all(
                                color: palette.carmine.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Icon(
                              KarminIcons.exam,
                              size: 16,
                              color: palette.accentText,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.studyUpcomingExam,
                                  style: KarminTypography.label(
                                    fontSize: 11,
                                    color: palette.muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  examLine,
                                  style: KarminTypography.body(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: palette.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      KarminPrimaryButton(
                        label: alreadySigned
                            ? l10n.studyAlreadySigned
                            : l10n.studySignUp,
                        icon: alreadySigned ? KarminIcons.verified : KarminIcons.edit,
                        onPressed: canSignUp
                            ? () => _confirmSignup(context, ref, l10n, exam)
                            : null,
                        height: 44,
                      ),
                      if (!canSignUp && !alreadySigned && examTitle != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.studySignUpUnavailable,
                          style: KarminTypography.body(
                            fontSize: 11,
                            color: palette.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignup(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ExamOffer exam,
  ) async {
    final date = exam.start == null
        ? '—'
        : DateFormat('EEE · MMM d · HH:mm').format(exam.start!);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: KarminPalette.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.studySignUpConfirmTitle(exam.subjectName),
                style: KarminTypography.title(
                  fontSize: 18,
                  color: KarminPalette.of(sheetContext).text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.studySignUpConfirmBody(date),
                style: KarminTypography.body(
                  fontSize: 13,
                  color: KarminPalette.of(sheetContext).muted,
                ),
              ),
              const SizedBox(height: 20),
              KarminPrimaryButton(
                label: l10n.studyConfirm,
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: Text(
                  l10n.studyCancel,
                  style: KarminTypography.body(
                    color: KarminPalette.of(sheetContext).muted,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      final result =
          await ref.read(studentSnapshotProvider.notifier).signUpForExam(exam.id);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } on NeptunException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    return KarminCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: palette.accentText),
              const SizedBox(width: 6),
              Text(
                label,
                style: KarminTypography.label(
                  fontSize: 11,
                  color: palette.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: KarminTypography.display(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.subject, required this.onTap});

  final TakenSubject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    return KarminCard(
      onTap: onTap,
      accentBar: true,
      accentBarColor:
          subject.grade != null ? palette.steel : palette.carmineBright,
      radius: KarminRadii.md,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: palette.field,
              border: Border.all(color: palette.hairline),
            ),
            child: Icon(
              _iconFor(subject.name),
              size: 15,
              color: palette.steel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: KarminTypography.body(
                    fontWeight: FontWeight.w500,
                    color: palette.text,
                  ),
                ),
                if (subject.code != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subject.code!,
                    style: KarminTypography.body(
                      fontSize: 11,
                      color: palette.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [palette.fieldHi, palette.field],
              ),
              border: Border.all(color: palette.hairline),
            ),
            child: Text(
              subject.gradeLabel,
              style: KarminTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('anal') ||
        lower.contains('math') ||
        lower.contains('disc')) {
      return KarminIcons.math;
    }
    if (lower.contains('prog') || lower.contains('code')) {
      return KarminIcons.code;
    }
    if (lower.contains('eng') ||
        lower.contains('angol') ||
        lower.contains('lang')) {
      return KarminIcons.language;
    }
    return KarminIcons.book;
  }
}
