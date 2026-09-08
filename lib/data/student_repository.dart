import 'dart:convert';

import 'package:karmin/api/dtos/calendar_event.dart';
import 'package:karmin/api/dtos/dashboard_snapshot.dart';
import 'package:karmin/api/dtos/exam_offer.dart';
import 'package:karmin/api/dtos/inbox_message.dart';
import 'package:karmin/api/dtos/student_profile.dart';
import 'package:karmin/api/dtos/taken_subject.dart';
import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_student_api.dart';
import 'package:karmin/data/cache_store.dart';

// ignore_for_file: prefer_initializing_formals

class StudentSnapshot {
  const StudentSnapshot({
    required this.events,
    required this.dashboard,
    required this.fetchedAt,
    this.subjects = const [],
    this.messages = const [],
    this.exams = const [],
    this.profile = const StudentProfile(),
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
  final List<TakenSubject> subjects;
  final List<InboxMessage> messages;
  final List<ExamOffer> exams;
  final StudentProfile profile;
  final DateTime fetchedAt;
  final bool fromCache;
  final String? errorMessage;

  bool get isEmpty =>
      events.isEmpty &&
      dashboard.gpa == null &&
      subjects.isEmpty &&
      messages.isEmpty;

  int get unreadCount {
    final fromMessages = messages.where((message) => message.unread).length;
    if (fromMessages > 0) {
      return fromMessages;
    }
    return dashboard.unreadCount;
  }

  TakenSubject? subjectById(String id) {
    for (final subject in subjects) {
      if (subject.id == id) {
        return subject;
      }
    }
    return null;
  }

  InboxMessage? messageById(String id) {
    for (final message in messages) {
      if (message.id == id) {
        return message;
      }
    }
    return null;
  }

  ExamOffer? get signupExam {
    final open = exams.where((exam) => exam.canSignUp && exam.id.isNotEmpty);
    if (open.isNotEmpty) {
      return open.first;
    }
    for (final exam in exams) {
      if (exam.id.isNotEmpty) {
        return exam;
      }
    }
    return exams.isEmpty ? null : exams.first;
  }

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

  StudentSnapshot copyWith({
    List<CalendarEvent>? events,
    DashboardSnapshot? dashboard,
    List<TakenSubject>? subjects,
    List<InboxMessage>? messages,
    List<ExamOffer>? exams,
    StudentProfile? profile,
    DateTime? fetchedAt,
    bool? fromCache,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StudentSnapshot(
      events: events ?? this.events,
      dashboard: dashboard ?? this.dashboard,
      subjects: subjects ?? this.subjects,
      messages: messages ?? this.messages,
      exams: exams ?? this.exams,
      profile: profile ?? this.profile,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      fromCache: fromCache ?? this.fromCache,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fetchedAt': fetchedAt.toIso8601String(),
      'dashboard': dashboard.toJson(),
      'events': events.map((event) => event.toJson()).toList(),
      'subjects': subjects.map((subject) => subject.toJson()).toList(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'exams': exams.map((exam) => exam.toJson()).toList(),
      'profile': profile.toJson(),
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
      subjects: parseCachedSubjects(json['subjects']),
      messages: parseCachedMessages(json['messages']),
      exams: parseCachedExams(json['exams']),
      profile: json['profile'] is Map
          ? StudentProfile.fromCacheJson(
              (json['profile'] as Map).map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
          : const StudentProfile(),
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      fromCache: fromCache,
    );
  }
}

/// Stale-while-revalidate student snapshot. JSON cache (Isar deferred).
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
      final cached = await readCache();
      final results = await Future.wait([
        _api.getCalendarEvents(start: weekStart, end: rangeEnd),
        _api.getDashboardAverages(),
        _api.getUnreadMessageCount(),
        _api.getDashboardCreditProgress(),
        _try(() => _api.getTakenSubjects()),
        _try(() => _api.getReceivedMessages()),
        _try(() => _api.getExamOffers()),
        _try(() => _api.getUserInfo()),
        _try(() => _api.getTrainingLabel()),
      ]);
      final credits = results[3] as ({int? completed, int? required});
      final subjects =
          (results[4] as List<TakenSubject>?) ?? cached?.subjects ?? const [];
      final messages =
          (results[5] as List<InboxMessage>?) ?? cached?.messages ?? const [];
      final exams = (results[6] as List<ExamOffer>?) ?? cached?.exams ?? const [];
      final profile = (results[7] as StudentProfile?) ??
          cached?.profile ??
          const StudentProfile();
      final training = results[8] as String?;
      final unreadFromList = messages.where((m) => m.unread).length;
      final unreadApi = results[2] as int;
      final snapshot = StudentSnapshot(
        events: results[0] as List<CalendarEvent>,
        dashboard: DashboardSnapshot(
          gpa: results[1] as double?,
          unreadCount: unreadFromList > 0 ? unreadFromList : unreadApi,
          completedCredits: credits.completed,
          requiredCredits: credits.required,
        ),
        subjects: subjects,
        messages: messages,
        exams: exams,
        profile: StudentProfile(
          displayName: profile.displayName,
          neptunCode: profile.neptunCode,
          training: profile.training ?? training ?? cached?.profile.training,
        ),
        fetchedAt: now,
      );
      await _cache.write(cacheKey, jsonEncode(snapshot.toJson()));
      return snapshot;
    } on NeptunException catch (error) {
      return _cachedOrEmpty(error.message);
    } catch (_) {
      return _cachedOrEmpty(const NeptunNetworkException().message);
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
        if (!fresh.isEmpty || fresh.errorMessage == null) {
          return fresh;
        }
        return cached.copyWith(
          fromCache: true,
          errorMessage: fresh.errorMessage,
        );
      }
    }
    return refresh();
  }

  Future<List<InboxPost>> loadMessagePosts(String messageId) {
    return _api.getMessagePosts(messageId);
  }

  Future<StudentSnapshot> markMessageRead(String messageId) async {
    final current = await readCache() ?? StudentSnapshot.empty();
    final message = current.messageById(messageId);
    if (message == null || !message.unread) {
      return current;
    }
    final postIds = message.postIds;
    try {
      final posts = postIds.isEmpty
          ? await _api.getMessagePosts(messageId)
          : const <InboxPost>[];
      final ids = postIds.isNotEmpty
          ? postIds
          : posts.map((post) => post.id).toList();
      await _api.markMessageRead(messageId: messageId, postIds: ids);
    } on NeptunException {
      // Still mark locally so the unread chip can move; list refresh will sync.
    }
    final updatedMessages = current.messages
        .map(
          (item) => item.id == messageId ? item.copyWith(unread: false) : item,
        )
        .toList();
    final unread = updatedMessages.where((item) => item.unread).length;
    final snapshot = current.copyWith(
      messages: updatedMessages,
      dashboard: DashboardSnapshot(
        gpa: current.dashboard.gpa,
        unreadCount: unread,
        completedCredits: current.dashboard.completedCredits,
        requiredCredits: current.dashboard.requiredCredits,
      ),
      fromCache: false,
      clearError: true,
    );
    await _cache.write(cacheKey, jsonEncode(snapshot.toJson()));
    return snapshot;
  }

  Future<({ExamSignupResult result, StudentSnapshot snapshot})> signUpForExam(
    String examId,
  ) async {
    final result = await _api.signUpForExam(examId);
    var snapshot = await readCache() ?? StudentSnapshot.empty();
    if (result.accepted) {
      snapshot = snapshot.copyWith(
        exams: snapshot.exams
            .map(
              (exam) => exam.id == examId
                  ? exam.copyWith(signedUp: true, canSignUp: false)
                  : exam,
            )
            .toList(),
        clearError: true,
      );
      await _cache.write(cacheKey, jsonEncode(snapshot.toJson()));
    }
    return (result: result, snapshot: snapshot);
  }

  Future<List<ExamOffer>> examsForSubject({
    required String subjectId,
    required String termId,
  }) {
    return _api.getExamsForSubject(subjectId: subjectId, termId: termId);
  }

  Future<void> clear() => _cache.delete(cacheKey);

  Future<StudentSnapshot> _cachedOrEmpty(String message) async {
    final cached = await readCache();
    if (cached != null) {
      return cached.copyWith(fromCache: true, errorMessage: message);
    }
    return StudentSnapshot.empty(errorMessage: message);
  }

  Future<T?> _try<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on NeptunException {
      return null;
    }
  }
}
