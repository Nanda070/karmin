/// Calendar row Karmin actually renders. Unknown JSON keys are ignored.
enum CalendarEventKind {
  classSession,
  exam,
  task,
  online,
  other,
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.kind,
    this.room,
    this.person,
    this.online = false,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final CalendarEventKind kind;
  final String? room;
  final String? person;
  final bool online;

  bool get isExam => kind == CalendarEventKind.exam;

  bool occursOn(DateTime day) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final target = DateTime(day.year, day.month, day.day);
    return !target.isBefore(startDay) && !target.isAfter(endDay);
  }

  bool matchesFilters(Set<String> filters) {
    if (filters.isEmpty) {
      return true;
    }
    final hits = <String>{};
    if (kind == CalendarEventKind.classSession) {
      hits.add('class');
    }
    if (kind == CalendarEventKind.exam) {
      hits.add('exam');
    }
    if (kind == CalendarEventKind.task) {
      hits.add('task');
    }
    if (online || kind == CalendarEventKind.online) {
      hits.add('online');
    }
    return hits.intersection(filters).isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'kind': kind.name,
      'room': room,
      'person': person,
      'online': online,
    };
  }

  factory CalendarEvent.fromCacheJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      start: DateTime.tryParse(json['start'] as String? ?? '') ?? DateTime.now(),
      end: DateTime.tryParse(json['end'] as String? ?? '') ?? DateTime.now(),
      kind: CalendarEventKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => CalendarEventKind.other,
      ),
      room: json['room'] as String?,
      person: json['person'] as String?,
      online: json['online'] == true,
    );
  }
}

/// Best-effort parse of ELTE / Óbuda-style `GetCalendarEvents` items.
/// Field names are not frozen — live JSON may still differ (PLAN.md §16).
List<CalendarEvent> parseCalendarEvents(dynamic raw) {
  final items = _asList(raw);
  final events = <CalendarEvent>[];
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (item is! Map) {
      continue;
    }
    final map = _stringKeyed(item);
    final start = parseFlexibleDate(
          _first(map, const [
            'startDate',
            'start',
            'fromDate',
            'beginDate',
            'eventStart',
            'from',
          ]),
        ) ??
        parseFlexibleDate(_first(map, const ['date']));
    if (start == null) {
      continue;
    }
    final end = parseFlexibleDate(
          _first(map, const [
            'endDate',
            'end',
            'toDate',
            'finishDate',
            'eventEnd',
            'to',
          ]),
        ) ??
        start.add(const Duration(hours: 2));
    final title = (_first(map, const [
              'title',
              'subjectName',
              'name',
              'eventName',
              'courseName',
              'description',
            ]) ??
            '')
        .toString()
        .trim();
    if (title.isEmpty) {
      continue;
    }
    final id = (_first(map, const [
              'id',
              'classInstanceId',
              'eventId',
              'appointmentId',
            ]) ??
            '$title-${start.toIso8601String()}')
        .toString();
    final room = _first(map, const [
      'rooms',
      'room',
      'location',
      'place',
      'classroom',
    ])?.toString();
    final person = _first(map, const [
      'tutors',
      'tutor',
      'lecturer',
      'teacherName',
      'instructor',
      'teacher',
      'personName',
    ])?.toString();
    final online = _isOnline(map);
    events.add(
      CalendarEvent(
        id: id,
        title: title,
        start: start,
        end: end,
        kind: _kindFrom(map, online: online),
        room: _nonEmpty(room),
        person: _nonEmpty(person),
        online: online,
      ),
    );
  }
  events.sort((a, b) => a.start.compareTo(b.start));
  return events;
}

String? _nonEmpty(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

CalendarEventKind _kindFrom(Map<String, dynamic> map, {required bool online}) {
  final raw = (_first(map, const [
            'eventType',
            'calendarEventType',
            'type',
            'courseType',
            'itemType',
          ]) ??
          '')
      .toString()
      .toLowerCase();
  if (raw.contains('exam') ||
      raw.contains('vizsg') ||
      raw == '2' ||
      raw == 'exam') {
    return CalendarEventKind.exam;
  }
  if (raw.contains('task') ||
      raw.contains('midterm') ||
      raw.contains('zh') ||
      raw == '3') {
    return CalendarEventKind.task;
  }
  if (raw.contains('online') || raw.contains('webex') || raw.contains('teams')) {
    return CalendarEventKind.online;
  }
  if (raw.contains('class') ||
      raw.contains('course') ||
      raw.contains('lecture') ||
      raw.contains('gyakor') ||
      raw.contains('ea') ||
      raw == '1' ||
      raw == '0') {
    return CalendarEventKind.classSession;
  }
  if (online) {
    return CalendarEventKind.online;
  }
  return CalendarEventKind.classSession;
}

bool _isOnline(Map<String, dynamic> map) {
  if (map['isOnline'] == true || map['online'] == true) {
    return true;
  }
  final meeting = map['webexMeetingId'] ?? map['onlineMeetingId'];
  return meeting != null && meeting.toString().trim().isNotEmpty;
}

Object? _first(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}

List<dynamic> _asList(dynamic raw) {
  if (raw is List) {
    return raw;
  }
  if (raw is Map) {
    final map = _stringKeyed(raw);
    for (final key in const ['items', 'events', 'calendarEvents', 'data']) {
      final nested = map[key];
      if (nested is List) {
        return nested;
      }
    }
  }
  return const [];
}

Map<String, dynamic> _stringKeyed(Map<dynamic, dynamic> map) {
  return map.map((key, value) => MapEntry(key.toString(), value));
}

DateTime? parseFlexibleDate(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is DateTime) {
    return raw;
  }
  if (raw is int) {
    return _fromEpoch(raw);
  }
  if (raw is double) {
    return _fromEpoch(raw.toInt());
  }
  final text = raw.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  final msDate = RegExp(r'/Date\((-?\d+)(?:[+-]\d+)?\)/').firstMatch(text);
  if (msDate != null) {
    return _fromEpoch(int.parse(msDate.group(1)!));
  }
  return DateTime.tryParse(text);
}

DateTime _fromEpoch(int value) {
  if (value.abs() > 9999999999) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
  }
  return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true)
      .toLocal();
}
