import 'dart:convert';

import 'package:karmin/api/dtos/calendar_event.dart';
import 'package:karmin/api/dtos/dashboard_snapshot.dart';
import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_student_api.dart';
import 'package:karmin/data/cache_store.dart';

// ignore_for_file: prefer_initializing_formals

class StudentSnapshot {
  const StudentSnapshot({
    required this.events,
    required this.dashboard,
    required this.fetchedAt,
    this.fromCache = false,
    this.errorMessage,
  });

  factory StudentSnapshot.empty({String? errorMessage}) {
    return StudentSnapshot(
      events: const [],
      dashboard: const DashboardSnapshot(),
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(0),
      errorMessage: errorMessage,
    );
  }

  final List<CalendarEvent> events;
  final DashboardSnapshot dashboard;
  final DateTime fetchedAt;
  final bool fromCache;
  final String? errorMessage;

  bool get isEmpty => events.isEmpty && dashboard.gpa == null;

  List<CalendarEvent> eventsOn(DateTime day) {
    return events.where((event) => event.occursOn(day)).toList();
  }

  CalendarEvent? nextClass(DateTime now) {
    final upcoming = events
        .where(
          (event) =>
              !event.isExam &&
              event.kind != CalendarEventKind.task &&
              event.end.isAfter(now),
        )
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    if (upcoming.isEmpty) {
      return null;
    }
    return upcoming.first;
  }

  CalendarEvent? nextExam(DateTime now) {
    final upcoming = events
        .where((event) => event.isExam && event.start.isAfter(now))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    if (upcoming.isEmpty) {
      return null;
    }
    return upcoming.first;
  }

  Map<String, dynamic> toJson() {
    return {
      'fetchedAt': fetchedAt.toIso8601String(),
      'dashboard': dashboard.toJson(),
      'events': events.map((event) => event.toJson()).toList(),
    };
  }

  factory StudentSnapshot.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = true,
  }) {
    final rawEvents = json['events'];
    return StudentSnapshot(
      events: rawEvents is List
          ? rawEvents
              .whereType<Map>()
              .map(
                (item) => CalendarEvent.fromCacheJson(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .toList()
          : const [],
      dashboard: json['dashboard'] is Map
          ? DashboardSnapshot.fromCacheJson(
              (json['dashboard'] as Map).map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
          : const DashboardSnapshot(),
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      fromCache: fromCache,
    );
  }
}

/// Stale-while-revalidate calendar + dashboard. JSON cache (Isar deferred).
class StudentRepository {
  StudentRepository({
    required NeptunStudentApi api,
    required CacheStore cache,
    DateTime Function()? clock,
    this.staleAfter = const Duration(minutes: 5),
  })  : _api = api,
        _cache = cache,
        _now = clock ?? DateTime.now;

  static const cacheKey = 'karmin.cache.student.v1';

  final NeptunStudentApi _api;
  final CacheStore _cache;
  final DateTime Function() _now;
  final Duration staleAfter;

  Future<StudentSnapshot?> readCache() async {
    final raw = await _cache.read(cacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return StudentSnapshot.fromJson(decoded);
      }
      if (decoded is Map) {
        return StudentSnapshot.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  bool isStale(StudentSnapshot snapshot) {
    return _now().difference(snapshot.fetchedAt) > staleAfter;
  }

  Future<StudentSnapshot> refresh() async {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final rangeEnd = weekStart.add(const Duration(days: 14));

    try {
      final results = await Future.wait([
        _api.getCalendarEvents(start: weekStart, end: rangeEnd),
        _api.getDashboardAverages(),
        _api.getUnreadMessageCount(),
        _api.getDashboardCreditProgress(),
      ]);
      final credits = results[3] as ({int? completed, int? required});
      final snapshot = StudentSnapshot(
        events: results[0] as List<CalendarEvent>,
        dashboard: DashboardSnapshot(
          gpa: results[1] as double?,
          unreadCount: results[2] as int,
          completedCredits: credits.completed,
          requiredCredits: credits.required,
        ),
        fetchedAt: now,
      );
      await _cache.write(cacheKey, jsonEncode(snapshot.toJson()));
      return snapshot;
    } on NeptunException catch (error) {
      final cached = await readCache();
      if (cached != null) {
        return StudentSnapshot(
          events: cached.events,
          dashboard: cached.dashboard,
          fetchedAt: cached.fetchedAt,
          fromCache: true,
          errorMessage: error.message,
        );
      }
      return StudentSnapshot.empty(errorMessage: error.message);
    } catch (_) {
      final cached = await readCache();
      if (cached != null) {
        return StudentSnapshot(
          events: cached.events,
          dashboard: cached.dashboard,
          fetchedAt: cached.fetchedAt,
          fromCache: true,
          errorMessage: const NeptunNetworkException().message,
        );
      }
      return StudentSnapshot.empty(
        errorMessage: const NeptunNetworkException().message,
      );
    }
  }

  /// Cache first (even if stale), then a network refresh.
  Future<StudentSnapshot> load({bool force = false}) async {
    if (!force) {
      final cached = await readCache();
      if (cached != null && !isStale(cached)) {
        return cached;
      }
      if (cached != null) {
        final fresh = await refresh();
        if (fresh.events.isNotEmpty || fresh.dashboard.gpa != null) {
          return fresh;
        }
        return StudentSnapshot(
          events: cached.events,
          dashboard: cached.dashboard,
          fetchedAt: cached.fetchedAt,
          fromCache: true,
          errorMessage: fresh.errorMessage,
        );
      }
    }
    return refresh();
  }

  Future<void> clear() => _cache.delete(cacheKey);
}
