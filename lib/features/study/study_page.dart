import 'package:flutter/material.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_card.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart' show KarminPageHeader;
import 'package:karmin/app/widgets/karmin_section_label.dart';
import 'package:karmin/l10n/app_localizations.dart';

class StudyPage extends StatelessWidget {
  const StudyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
        padding: const EdgeInsets.only(bottom: KarminSpacing.xxl),
        children: [
          KarminPageHeader(title: l10n.tabStudy),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KarminSpacing.pageX),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: l10n.chipGpa,
                        value: l10n.demoGpa,
                      ),
                    ),
                    const SizedBox(width: KarminSpacing.sm),
                    Expanded(
                      child: _StatCard(
                        label: l10n.studyCredits,
                        value: l10n.demoCredits,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KarminSpacing.xl),
                KarminSectionLabel(l10n.studySubjects),
                const SizedBox(height: KarminSpacing.sm),
                _SubjectRow(title: l10n.demoSubjectAnalysis, grade: '4'),
                const SizedBox(height: KarminSpacing.sm),
                _SubjectRow(title: l10n.demoSubjectProgramming, grade: '5'),
                const SizedBox(height: KarminSpacing.sm),
                _SubjectRow(title: l10n.demoSubjectEnglish, grade: '—'),
                const SizedBox(height: KarminSpacing.lg),
                KarminCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.studyUpcomingExam,
                        style: KarminTypography.label(fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.demoExamLine,
                              style: KarminTypography.body(
                                fontSize: 13,
                                color: KarminColors.muted,
                              ),
                            ),
                          ),
                          Text(
                            l10n.studySignUp,
                            style: KarminTypography.body(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: KarminColors.carmine,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return KarminCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: KarminTypography.label(fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: KarminTypography.display(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.title, required this.grade});

  final String title;
  final String grade;

  @override
  Widget build(BuildContext context) {
    return KarminCard(
      radius: KarminRadii.md,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: KarminTypography.body(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: KarminColors.navy,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: KarminColors.hairline),
            ),
            child: Text(
              grade,
              style: KarminTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
