import 'package:karmin/api/dtos/calendar_event.dart';
import 'package:karmin/api/dtos/dashboard_snapshot.dart';
import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_client.dart';

/// Authenticated student reads for Stage 2 (calendar + dashboard chips).
abstract interface class NeptunStudentApi {
  Future<List<CalendarEvent>> getCalendarEvents({
    required DateTime start,
    required DateTime end,
  });

  Future<double?> getDashboardAverages();

  Future<({int? completed, int? required})> getDashboardCreditProgress();

  Future<int> getUnreadMessageCount();
}

/// Live ELTE HTTPS reads. JWT is attached by [NeptunClient] interceptors.
class LiveNeptunStudentApi implements NeptunStudentApi {
  LiveNeptunStudentApi(this._client);

  final NeptunClient _client;

  @override
  Future<List<CalendarEvent>> getCalendarEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    final raw = await _client.getData(
      'Calendar/GetCalendarEvents',
      query: {
        'startDate': _neptunDate(start),
        'endDate': _neptunDate(end),
        'displayClasses': 'true',
        'displayExams': 'true',
        'displayPeriods': 'true',
        'displayTasks': 'true',
        'displayOnlineMeetings': 'true',
        'displayOtherEvents': 'true',
      },
    );
    return parseCalendarEvents(raw);
  }

  @override
  Future<double?> getDashboardAverages() async {
    try {
      final raw = await _client.getData('Dashboard/GetAverages');
      return parseGpa(raw);
    } on NeptunForbiddenException {
      return null;
    }
  }

  @override
  Future<({int? completed, int? required})> getDashboardCreditProgress() async {
    try {
      final raw = await _client.getData('dashboard/creditprogress');
      return parseCreditProgress(raw);
    } on NeptunForbiddenException {
      return (completed: null, required: null);
    }
  }

  @override
  Future<int> getUnreadMessageCount() async {
    try {
      final raw = await _client.getData('Message/GetUnreadedMessagesCount');
      return parseUnreadCount(raw);
    } on NeptunForbiddenException {
      return 0;
    }
  }

  static String _neptunDate(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}T'
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}.000';
  }
}

/// Labeled debug / web path. Same demo week the Stage 0 screens used.
class DebugNeptunStudentApi implements NeptunStudentApi {
  DebugNeptunStudentApi({DateTime Function()? clock})
      : _now = clock ?? DateTime.now;

  final DateTime Function() _now;

  @override
  Future<List<CalendarEvent>> getCalendarEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    return debugCalendarEvents(_now())
        .where((event) => !event.end.isBefore(start) && !event.start.isAfter(end))
        .toList();
  }

  @override
  Future<double?> getDashboardAverages() async => 4.32;

  @override
  Future<({int? completed, int? required})> getDashboardCreditProgress() async {
    return (completed: 27, required: 30);
  }

  @override
  Future<int> getUnreadMessageCount() async => 3;
}

List<CalendarEvent> debugCalendarEvents([DateTime? now]) {
  final moment = now ?? DateTime.now();
  final today = DateTime(moment.year, moment.month, moment.day);
  final monday = today.subtract(Duration(days: today.weekday - 1));
  final thursday = monday.add(const Duration(days: 3));
  return [
    CalendarEvent(
      id: 'debug-analysis',
      title: 'Analysis II',
      start: DateTime(today.year, today.month, today.day, 8),
      end: DateTime(today.year, today.month, today.day, 10),
      kind: CalendarEventKind.classSession,
      room: 'D 3-510',
      person: 'Dr. Nagy',
    ),
    CalendarEvent(
      id: 'debug-programming',
      title: 'Programming',
      start: DateTime(today.year, today.month, today.day, 10, 15),
      end: DateTime(today.year, today.month, today.day, 12),
      kind: CalendarEventKind.classSession,
      room: 'Lágymányos 2.502',
      person: 'Kovács Péter',
    ),
    CalendarEvent(
      id: 'debug-exam',
      title: 'Exam · Discrete math',
      start: DateTime(thursday.year, thursday.month, thursday.day, 10),
      end: DateTime(thursday.year, thursday.month, thursday.day, 12),
      kind: CalendarEventKind.exam,
      room: 'Trefort',
      person: 'Exam hall',
    ),
  ];
}
