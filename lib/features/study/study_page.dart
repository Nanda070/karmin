import 'package:flutter/material.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_card.dart';
import 'package:karmin/app/widgets/karmin_primary_button.dart';
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
        KarminPageHeader(
          title: l10n.tabStudy,
          trailing: Icon(
            KarminIcons.study,
            size: 20,
            color: KarminColors.muted,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KarminSpacing.pageX),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: KarminIcons.trending,
                      label: l10n.chipGpa,
                      value: l10n.demoGpa,
                    ),
                  ),
                  const SizedBox(width: KarminSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      icon: KarminIcons.layers,
                      label: l10n.studyCredits,
                      value: l10n.demoCredits,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KarminSpacing.xl),
              KarminSectionLabel(l10n.studySubjects),
              const SizedBox(height: KarminSpacing.sm),
              _SubjectRow(
                icon: KarminIcons.math,
                title: l10n.demoSubjectAnalysis,
                grade: '4',
              ),
              const SizedBox(height: KarminSpacing.sm),
              _SubjectRow(
                icon: KarminIcons.code,
                title: l10n.demoSubjectProgramming,
                grade: '5',
              ),
              const SizedBox(height: KarminSpacing.sm),
              _SubjectRow(
                icon: KarminIcons.language,
                title: l10n.demoSubjectEnglish,
                grade: '—',
              ),
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
                            color: KarminColors.carmine.withValues(alpha: 0.18),
                            border: Border.all(
                              color: KarminColors.carmine.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            KarminIcons.exam,
                            size: 16,
                            color: KarminColors.carmineBright,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.studyUpcomingExam,
                                style: KarminTypography.label(fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.demoExamLine,
                                style: KarminTypography.body(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    KarminPrimaryButton(
                      label: l10n.studySignUp,
                      icon: KarminIcons.edit,
                      onPressed: () {},
                      height: 44,
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
    return KarminCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: KarminColors.carmineBright),
              const SizedBox(width: 6),
              Text(label, style: KarminTypography.label(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: KarminTypography.display(
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.icon,
    required this.title,
    required this.grade,
  });

  final IconData icon;
  final String title;
  final String grade;

  @override
  Widget build(BuildContext context) {
    return KarminCard(
      radius: KarminRadii.md,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: KarminColors.navy,
              border: Border.all(color: KarminColors.hairline),
            ),
            child: Icon(icon, size: 15, color: KarminColors.steel),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: KarminTypography.body(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A2438), KarminColors.navy],
              ),
              border: Border.all(color: KarminColors.hairline),
            ),
            child: Text(
              grade,
              style: KarminTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
