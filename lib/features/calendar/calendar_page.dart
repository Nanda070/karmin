import 'package:flutter/material.dart';

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
          KarminPageHeader(title: l10n.tabCalendar),
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
                    accent: KarminColors.steel,
                  ),
                  const SizedBox(height: KarminSpacing.sm),
                  _EventCard(
                    time: l10n.demoEventProgrammingTime,
                    title: l10n.demoEventProgrammingTitle,
                    room: l10n.demoEventProgrammingRoom,
                    accent: KarminColors.steel,
                  ),
                  const SizedBox(height: KarminSpacing.sm),
                ],
                if (_filters.contains('exam') || _filters.isEmpty)
                  _EventCard(
                    time: l10n.demoEventExamTime,
                    title: l10n.demoEventExamTitle,
                    room: l10n.demoEventExamRoom,
                    accent: KarminColors.carmine,
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
      borderRadius: KarminRadii.smBorder,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 36,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? KarminColors.navy : Colors.transparent,
          borderRadius: KarminRadii.smBorder,
          border: selected
              ? Border.all(color: KarminColors.hairline)
              : null,
        ),
        child: Column(
          children: [
            Text(
              weekday,
              style: KarminTypography.label(
                fontSize: 11,
                color: selected ? KarminColors.text : KarminColors.muted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              day,
              style: KarminTypography.body(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
    required this.accent,
  });

  final String time;
  final String title;
  final String room;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return KarminCard(
      accentBar: true,
      accentBarColor: accent,
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(time, style: KarminTypography.label(fontSize: 11)),
          const SizedBox(height: 2),
          Text(title, style: KarminTypography.body(fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            room,
            style: KarminTypography.body(fontSize: 12, color: KarminColors.muted),
          ),
        ],
      ),
    );
  }
}
