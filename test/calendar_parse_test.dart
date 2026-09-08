import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/api/dtos/calendar_event.dart';
import 'package:karmin/api/dtos/dashboard_snapshot.dart';

void main() {
  test('parses ISO calendar events and ignores unknown keys', () {
    final fixture = jsonDecode(
      File('test/fixtures/calendar_events.json').readAsStringSync(),
    );
    final events = parseCalendarEvents(fixture);
    expect(events.map((e) => e.title), contains('Analysis II'));
    final analysis = events.firstWhere((e) => e.title == 'Analysis II');
    expect(analysis.room, 'D 3-510');
    expect(analysis.kind, CalendarEventKind.classSession);
    expect(analysis.start.hour, 8);
  });

  test('maps numeric exam type and Microsoft Date', () {
    final events = parseCalendarEvents({
      'data': [
        {
          'title': 'Algebra exam',
          'start': '/Date(1757322000000)/',
          'end': '/Date(1757329200000)/',
          'eventType': 2,
          'rooms': 'Aula',
        },
      ],
    });
    expect(events, hasLength(1));
    expect(events.single.kind, CalendarEventKind.exam);
    expect(events.single.room, 'Aula');
  });

  test('parses GPA and unread envelopes', () {
    expect(parseGpa({'cumulativeAverage': 4.32}), 4.32);
    expect(parseUnreadCount({'count': 3}), 3);
    final credits = parseCreditProgress({
      'completedCredits': 27,
      'requiredCredits': 30,
    });
    expect(credits.completed, 27);
    expect(credits.required, 30);
  });
}
