import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:karmin/api/dtos/calendar_event.dart';
import 'package:karmin/app/theme.dart';
import 'package:karmin/app/widgets/karmin_card.dart';
import 'package:karmin/app/widgets/karmin_filter_chip.dart';
import 'package:karmin/app/widgets/karmin_icons.dart';
import 'package:karmin/app/widgets/karmin_scaffold.dart' show KarminPageHeader;
import 'package:karmin/app/widgets/karmin_segmented.dart';
import 'package:karmin/app/widgets/karmin_status.dart';
import 'package:karmin/data/providers.dart';
import 'package:karmin/data/student_repository.dart';
import 'package:karmin/l10n/app_localizations.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  int _mode = 0;
  late DateTime _weekStart;
  late int _dayIndex;
  final Set<String> _filters = {'class', 'exam'};

  static const _weekdayLetters = ['M', 'T', 'W', 'Th', 'F', 'S', 'Su'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _weekStart = today.subtract(Duration(days: today.weekday - 1));
    _dayIndex = today.weekday - 1;
  }

  DateTime get _selectedDay => _weekStart.add(Duration(days: _dayIndex));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = KarminPalette.of(context);
    final async = ref.watch(studentSnapshotProvider);
    final snapshot = async.valueOrNull ?? StudentSnapshot.empty();
    final visible = _visibleEvents(snapshot);
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
            title: l10n.tabCalendar,
            trailing: Icon(
              KarminIcons.calendarRange,
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
                KarminSegmented(
                  labels: [l10n.calendarWeek, l10n.calendarList],
                  index: _mode,
                  onChanged: (i) => setState(() => _mode = i),
                ),
                const SizedBox(height: KarminSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 7; i++)
                      _DayCell(
                        weekday: _weekdayLetters[i],
                        day: '${_weekStart.add(Duration(days: i)).day}',
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
                if (visible.isEmpty)
                  KarminEmptyState(
                    message: l10n.calendarEmpty,
                    icon: KarminIcons.calendar,
                  )
                else
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i > 0) const SizedBox(height: KarminSpacing.sm),
                    _EventCard(
                      time: _timeLabel(visible[i]),
                      title: visible[i].title,
                      room: visible[i].room ?? '—',
                      professor: visible[i].person ?? '—',
                      accent: visible[i].isExam
                          ? palette.carmine
                          : palette.steel,
                      isExam: visible[i].isExam,
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<CalendarEvent> _visibleEvents(StudentSnapshot snapshot) {
    final source = _mode == 0
        ? snapshot.eventsOn(_selectedDay)
        : snapshot.events
            .where(
              (event) =>
                  !event.start.isBefore(_weekStart) &&
                  event.start.isBefore(_weekStart.add(const Duration(days: 7))),
            )
            .toList();
    return source.where((event) => event.matchesFilters(_filters)).toList();
  }

  String _timeLabel(CalendarEvent event) {
    final start = DateFormat('H:mm').format(event.start);
    final end = DateFormat('H:mm').format(event.end);
    if (event.isExam) {
      return start;
    }
    return '$start–$end';
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
    final palette = KarminPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$weekday $day',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
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
                        palette.carmine.withValues(alpha: 0.35),
                        palette.field,
                      ],
                    )
                  : null,
              border: Border.all(
                color: selected
                    ? palette.carmine.withValues(alpha: 0.55)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                Text(
                  weekday,
                  style: KarminTypography.label(
                    fontSize: 10,
                    color: selected ? palette.text : palette.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  day,
                  style: KarminTypography.body(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? palette.text : palette.muted,
                  ),
                ),
              ],
            ),
          ),
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
              Text(
                time,
                style: KarminTypography.label(
                  fontSize: 11,
                  color: KarminPalette.of(context).muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: KarminTypography.body(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: KarminPalette.of(context).text,
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
          Icon(icon, size: 12, color: KarminPalette.of(context).muted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: KarminTypography.body(
                fontSize: 12,
                color: KarminPalette.of(context).muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
