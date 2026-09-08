import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:karmin/api/dtos/exam_offer.dart';
import 'package:karmin/api/dtos/taken_subject.dart';
import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_card.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart'
    show KarminCircleButton, KarminPageHeader;
import 'package:karmin/app/widgets/karmin_section_label.dart';
import 'package:karmin/app/widgets/karmin_status.dart';
import 'package:karmin/data/providers.dart';
import 'package:karmin/data/student_repository.dart';
import 'package:karmin/l10n/app_localizations.dart';

class SubjectPage extends ConsumerWidget {
  const SubjectPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = KarminPalette.of(context);
    final snapshot =
        ref.watch(studentSnapshotProvider).valueOrNull ?? StudentSnapshot.empty();
    final subject = snapshot.subjectById(subjectId);

    return ListView(
      padding: const EdgeInsets.only(bottom: KarminSpacing.xxl),
      children: [
        KarminPageHeader(
          leading: KarminCircleButton(
            onPressed: () => context.pop(),
            icon: KarminIcons.chevronLeft,
            tooltip: l10n.tabStudy,
          ),
          title: subject?.name ?? l10n.tabStudy,
          titleStyle: KarminTypography.display(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: palette.text,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KarminSpacing.pageX),
          child: subject == null
              ? KarminEmptyState(
                  message: l10n.studyEmpty,
                  icon: KarminIcons.book,
                )
              : _SubjectBody(subject: subject, snapshot: snapshot),
        ),
      ],
    );
  }
}

class _SubjectBody extends ConsumerWidget {
  const _SubjectBody({required this.subject, required this.snapshot});

  final TakenSubject subject;
  final StudentSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final exams = snapshot.exams
        .where(
          (exam) =>
              exam.subjectId == subject.id ||
              exam.subjectName.toLowerCase() == subject.name.toLowerCase(),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KarminCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _Fact(
                label: l10n.subjectCode,
                value: subject.code ?? '—',
              ),
              const SizedBox(height: 12),
              _Fact(
                label: l10n.studyCredits,
                value: subject.credits?.toString() ?? '—',
              ),
              const SizedBox(height: 12),
              _Fact(
                label: l10n.chipGpa,
                value: subject.gradeLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: KarminSpacing.xl),
        KarminSectionLabel(l10n.subjectExams),
        const SizedBox(height: KarminSpacing.sm),
        if (exams.isEmpty)
          KarminEmptyState(
            message: l10n.subjectEmptyExams,
            icon: KarminIcons.exam,
          )
        else
          for (final exam in exams) ...[
            _ExamLine(exam: exam),
            const SizedBox(height: KarminSpacing.sm),
          ],
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = KarminPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: KarminTypography.label(fontSize: 12, color: palette.muted),
          ),
        ),
        Text(
          value,
          style: KarminTypography.body(
            fontWeight: FontWeight.w600,
            color: palette.text,
          ),
        ),
      ],
    );
  }
}

class _ExamLine extends StatelessWidget {
  const _ExamLine({required this.exam});

  final ExamOffer exam;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = KarminPalette.of(context);
    final when = exam.start == null
        ? '—'
        : DateFormat('EEE · MMM d · HH:mm').format(exam.start!);
    return KarminCard(
      accentBar: true,
      accentBarColor: palette.carmine,
      radius: KarminRadii.md,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      child: Row(
        children: [
          Icon(KarminIcons.exam, size: 16, color: palette.accentText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.subjectName,
                  style: KarminTypography.body(
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  when,
                  style: KarminTypography.body(
                    fontSize: 12,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            exam.signedUp ? l10n.studyAlreadySigned : l10n.studySignUp,
            style: KarminTypography.label(
              fontSize: 11,
              color: exam.signedUp ? palette.muted : palette.accentText,
            ),
          ),
        ],
      ),
    );
  }
}
