import 'package:flutter/material.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';

import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_card.dart';
import 'package:karmin/app/widgets/karmin_filter_chip.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart' show KarminPageHeader;
import 'package:karmin/app/widgets/karmin_segmented.dart';
import 'package:karmin/l10n/app_localizations.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _mode = 0;
  int _dayIndex = 0;
  final Set<String> _filters = {'class', 'exam'};

  static const _days = [
    ('M', '8'),
    ('T', '9'),
    ('W', '10'),
    ('Th', '11'),
    ('F', '12'),
    ('S', '13'),
    ('Su', '14'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: KarminSpacing.xxl),
      children: [
        KarminPageHeader(
          title: l10n.tabCalendar,
          trailing: Icon(
            KarminIcons.calendarRange,
            size: 20,
            color: KarminColors.muted,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KarminSpacing.pageX),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KarminSegmented(
                labels: [l10n.calendarWeek, l10n.calendarList],
                index: _mode,
                onChanged: (i) => setState(() => _mode = i),
              ),
              const SizedBox(height: KarminSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < _days.length; i++)
                    _DayCell(
                      weekday: _days[i].$1,
                      day: _days[i].$2,
                      selected: i == _dayIndex,
                      onTap: () => setState(() => _dayIndex = i),
                    ),
                ],
              ),
              const SizedBox(height: KarminSpacing.lg),
              Wrap(
                spacing: KarminSpacing.sm,
                runSpacing: KarminSpacing.sm,
                children: [
                  KarminFilterChip(
                    label: l10n.filterClass,
                    selected: _filters.contains('class'),
                    onTap: () => _toggleFilter('class'),
                  ),
                  KarminFilterChip(
                    label: l10n.filterExam,
                    selected: _filters.contains('exam'),
                    onTap: () => _toggleFilter('exam'),
                  ),
                  KarminFilterChip(
                    label: l10n.filterTask,
                    selected: _filters.contains('task'),
                    onTap: () => _toggleFilter('task'),
                  ),
                  KarminFilterChip(
                    label: l10n.filterOnline,
                    selected: _filters.contains('online'),
                    onTap: () => _toggleFilter('online'),
                  ),
                ],
              ),
              const SizedBox(height: KarminSpacing.lg),
              if (_filters.contains('class') || _filters.isEmpty) ...[
                _EventCard(
                  time: l10n.demoEventAnalysisTime,
                  title: l10n.demoSubjectAnalysis,
                  room: l10n.demoEventAnalysisRoom,
                  professor: 'Dr. Nagy',
                  accent: KarminColors.steel,
                ),
                const SizedBox(height: KarminSpacing.sm),
                _EventCard(
                  time: l10n.demoEventProgrammingTime,
                  title: l10n.demoEventProgrammingTitle,
                  room: l10n.demoEventProgrammingRoom,
                  professor: 'Kovács Péter',
                  accent: KarminColors.steel,
                ),
                const SizedBox(height: KarminSpacing.sm),
              ],
              if (_filters.contains('exam') || _filters.isEmpty)
                _EventCard(
                  time: l10n.demoEventExamTime,
                  title: l10n.demoEventExamTitle,
                  room: l10n.demoEventExamRoom,
                  professor: 'Exam hall',
                  accent: KarminColors.carmine,
                  isExam: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleFilter(String key) {
    setState(() {
      if (_filters.contains(key)) {
        _filters.remove(key);
      } else {
        _filters.add(key);
      }
    });
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.weekday,
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final String weekday;
  final String day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    KarminColors.carmine.withValues(alpha: 0.35),
                    KarminColors.navy,
                  ],
                )
              : null,
          border: Border.all(
            color: selected
                ? KarminColors.carmine.withValues(alpha: 0.55)
                : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              weekday,
              style: KarminTypography.label(
                fontSize: 10,
                color: selected ? KarminColors.text : KarminColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              day,
              style: KarminTypography.body(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? KarminColors.text : KarminColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.time,
    required this.title,
    required this.room,
    required this.professor,
    required this.accent,
    this.isExam = false,
  });

  final String time;
  final String title;
  final String room;
  final String professor;
  final Color accent;
  final bool isExam;

  @override
  Widget build(BuildContext context) {
    return KarminCard(
      accentBar: true,
      accentBarColor: accent,
      padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExam ? KarminIcons.exam : KarminIcons.book,
                size: 14,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(time, style: KarminTypography.label(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: KarminTypography.body(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _IconMeta(icon: KarminIcons.mapPin, text: room),
              const SizedBox(width: 14),
              _IconMeta(icon: KarminIcons.person, text: professor),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconMeta extends StatelessWidget {
  const _IconMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: KarminColors.muted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: KarminTypography.body(
                fontSize: 12,
                color: KarminColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
