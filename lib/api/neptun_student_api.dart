import 'package:karmin/api/dtos/calendar_event.dart';
import 'package:karmin/api/dtos/dashboard_snapshot.dart';
import 'package:karmin/api/dtos/exam_offer.dart';
import 'package:karmin/api/dtos/inbox_message.dart';
import 'package:karmin/api/dtos/json_util.dart';
import 'package:karmin/api/dtos/student_profile.dart';
import 'package:karmin/api/dtos/taken_subject.dart';
import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_client.dart';

/// Authenticated student reads/writes. Stage 2 calendar + Stage 3 study/inbox.
abstract interface class NeptunStudentApi {
  Future<List<CalendarEvent>> getCalendarEvents({
    required DateTime start,
    required DateTime end,
  });

  Future<double?> getDashboardAverages();

  Future<({int? completed, int? required})> getDashboardCreditProgress();

  Future<int> getUnreadMessageCount();

  Future<StudentProfile> getUserInfo();

  Future<String?> getTrainingLabel();

  Future<List<TakenSubject>> getTakenSubjects();

  Future<List<ExamOffer>> getExamOffers();

  Future<List<ExamOffer>> getExamsForSubject({
    required String subjectId,
    required String termId,
  });

  Future<ExamSignupResult> signUpForExam(String examId);

  Future<List<InboxMessage>> getReceivedMessages();

  Future<List<InboxPost>> getMessagePosts(String messageId);

  Future<void> markMessageRead({
    required String messageId,
    required List<String> postIds,
  });
}

/// Live ELTE HTTPS. JWT is attached by [NeptunClient] interceptors.
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

  @override
  Future<StudentProfile> getUserInfo() async {
    try {
      final raw = await _client.getData('UserInfo');
      return parseStudentProfile(raw);
    } on NeptunForbiddenException {
      return const StudentProfile();
    }
  }

  @override
  Future<String?> getTrainingLabel() async {
    try {
      final raw = await _client.getData('ContextUserProfile/MyTrainings');
      final label = parseTrainingLabel(raw);
      if (label != null) {
        return label;
      }
    } on NeptunException {
      // Fall through to shorter path.
    }
    try {
      final raw = await _client.getData('MyTrainings');
      return parseTrainingLabel(raw);
    } on NeptunForbiddenException {
      return null;
    }
  }

  @override
  Future<List<TakenSubject>> getTakenSubjects() async {
    try {
      final terms = parseSubjectTerms(
        await _client.getData('TakenSubjects/Terms'),
      );
      final term = pickCurrentTerm(terms);
      if (term == null) {
        return const [];
      }
      final raw = await _client.getData(
        'TakenSubjects',
        query: {
          'request.termId': term.id,
          'sortAndPage.firstRow': 0,
          'sortAndPage.lastRow': 100,
          'sortAndPage.subjectName': 'asc',
        },
      );
      var subjects = parseTakenSubjects(
        raw,
        termId: term.id,
        termLabel: term.label,
      );
      try {
        final results = await _client.getData(
          'SubjectCourse/GetSubjectResultsList',
          query: {'termId': term.id},
        );
        subjects = mergeSubjectGrades(subjects, results);
      } on NeptunException {
        // Óbuda/ELTE often return empty/404 here — keep list grades.
      }
      return subjects;
    } on NeptunForbiddenException {
      return const [];
    }
  }

  @override
  Future<List<ExamOffer>> getExamOffers() async {
    try {
      final raw = await _client.getData(
        'ExamOverview/GetDashboardExamEntriesInActualTerm',
      );
      final parsed = parseExamOffers(raw);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    } on NeptunException {
      // Fall through to the other dashboard list.
    }
    try {
      final raw = await _client.getData(
        'ExamOverview/GetDashboardExamEntries',
      );
      return parseExamOffers(raw);
    } on NeptunForbiddenException {
      return const [];
    }
  }

  @override
  Future<List<ExamOffer>> getExamsForSubject({
    required String subjectId,
    required String termId,
  }) async {
    try {
      final raw = await _client.getData(
        'ExamRegistration/GetExamsList',
        query: {'subjectId': subjectId, 'termId': termId},
      );
      return parseExamOffers(raw);
    } on NeptunForbiddenException {
      return const [];
    }
  }

  @override
  Future<ExamSignupResult> signUpForExam(String examId) async {
    final raw = await _client.postData(
      'ExamRegistration/SignUpForExam',
      data: {'examId': examId},
    );
    final message = extractNeptunMessage(raw);
    final accepted = !_looksLikeFailure(raw, message);
    return ExamSignupResult(
      message: message ??
          (accepted
              ? 'Neptun accepted the signup.'
              : 'Neptun rejected the signup.'),
      accepted: accepted,
    );
  }

  @override
  Future<List<InboxMessage>> getReceivedMessages() async {
    try {
      final raw = await _client.getData(
        'Message/GetReceivedMessages',
        query: {
          'firstRow': 0,
          'lastRow': 40,
          'filterType': 0,
        },
      );
      return parseInboxMessages(raw);
    } on NeptunForbiddenException {
      return const [];
    }
  }

  @override
  Future<List<InboxPost>> getMessagePosts(String messageId) async {
    final raw = await _client.getData(
      'Messages/$messageId/Posts',
      query: {'messageId': messageId},
    );
    return parseInboxPosts(raw);
  }

  @override
  Future<void> markMessageRead({
    required String messageId,
    required List<String> postIds,
  }) async {
    if (postIds.isEmpty) {
      return;
    }
    await _client.postData(
      'Messages/$messageId/Posts/Processed',
      data: {'postIds': postIds},
    );
  }

  static bool _looksLikeFailure(dynamic raw, String? message) {
    if (raw is Map) {
      final map = stringKeyed(raw);
      final type = (map['type'] ?? map['notificationType'] ?? '')
          .toString()
          .toLowerCase();
      if (type.contains('error') || type.contains('fail')) {
        return true;
      }
      if (map['success'] == false || map['isSuccess'] == false) {
        return true;
      }
    }
    final lower = (message ?? '').toLowerCase();
    return lower.contains('error') ||
        lower.contains('hiba') ||
        lower.contains('rejected') ||
        lower.contains('cannot') ||
        lower.contains('failed');
  }

  static String _neptunDate(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}T'
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}.000';
  }
}

/// Labeled debug / web path. Same demo week + Study/Inbox fixtures as Stage 0.
class DebugNeptunStudentApi implements NeptunStudentApi {
  DebugNeptunStudentApi({DateTime Function()? clock})
      : _now = clock ?? DateTime.now;

  final DateTime Function() _now;
  final Set<String> _signedExamIds = {};
  final Set<String> _readMessageIds = {};

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
  Future<int> getUnreadMessageCount() async {
    return debugInboxMessages(_now(), readIds: _readMessageIds)
        .where((message) => message.unread)
        .length;
  }

  @override
  Future<StudentProfile> getUserInfo() async {
    return const StudentProfile(
      displayName: 'Adnan Huseynli',
      neptunCode: 'ABC123',
      training: 'Computer Science BSc',
    );
  }

  @override
  Future<String?> getTrainingLabel() async => 'Computer Science BSc';

  @override
  Future<List<TakenSubject>> getTakenSubjects() async => debugTakenSubjects();

  @override
  Future<List<ExamOffer>> getExamOffers() async {
    return debugExamOffers(_now(), signedIds: _signedExamIds);
  }

  @override
  Future<List<ExamOffer>> getExamsForSubject({
    required String subjectId,
    required String termId,
  }) async {
    return debugExamOffers(_now(), signedIds: _signedExamIds)
        .where((exam) => exam.subjectId == subjectId)
        .toList();
  }

  @override
  Future<ExamSignupResult> signUpForExam(String examId) async {
    _signedExamIds.add(examId);
    return const ExamSignupResult(
      message: 'Signed up (debug mock — not Neptun).',
      accepted: true,
    );
  }

  @override
  Future<List<InboxMessage>> getReceivedMessages() async {
    return debugInboxMessages(_now(), readIds: _readMessageIds);
  }

  @override
  Future<List<InboxPost>> getMessagePosts(String messageId) async {
    return debugInboxPosts(messageId, _now());
  }

  @override
  Future<void> markMessageRead({
    required String messageId,
    required List<String> postIds,
  }) async {
    _readMessageIds.add(messageId);
  }
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

List<TakenSubject> debugTakenSubjects() {
  return const [
    TakenSubject(
      id: 'debug-analysis',
      name: 'Analysis II',
      code: 'IP-08bANAL2',
      credits: 6,
      grade: 4,
      termId: 'debug-term',
      termLabel: '2025/26/1',
    ),
    TakenSubject(
      id: 'debug-programming',
      name: 'Programming',
      code: 'IP-08bPROG',
      credits: 5,
      grade: 5,
      termId: 'debug-term',
      termLabel: '2025/26/1',
    ),
    TakenSubject(
      id: 'debug-english',
      name: 'English practice',
      code: 'IP-08bANGOL',
      credits: 2,
      termId: 'debug-term',
      termLabel: '2025/26/1',
    ),
  ];
}

List<ExamOffer> debugExamOffers(
  DateTime now, {
  Set<String> signedIds = const {},
}) {
  final today = DateTime(now.year, now.month, now.day);
  final monday = today.subtract(Duration(days: today.weekday - 1));
  final thursday = monday.add(const Duration(days: 3));
  final signed = signedIds.contains('debug-exam-1');
  return [
    ExamOffer(
      id: 'debug-exam-1',
      subjectName: 'Discrete math',
      subjectId: 'debug-discrete',
      start: DateTime(thursday.year, thursday.month, thursday.day, 10),
      room: 'Trefort',
      canSignUp: !signed,
      signedUp: signed,
    ),
  ];
}

List<InboxMessage> debugInboxMessages(
  DateTime now, {
  Set<String> readIds = const {},
}) {
  final today = DateTime(now.year, now.month, now.day, 14, 2);
  return [
    InboxMessage(
      id: 'debug-msg-1',
      sender: 'Registrar',
      subject: 'Exam period schedule',
      sentAt: today,
      unread: !readIds.contains('debug-msg-1'),
      preview: 'The spring exam period dates are now in Neptun.',
      postIds: const ['debug-post-1'],
    ),
    InboxMessage(
      id: 'debug-msg-2',
      sender: 'Neptun',
      subject: 'New grade: Analysis II',
      sentAt: today.subtract(const Duration(days: 1)),
      unread: !readIds.contains('debug-msg-2'),
      preview: 'A new result was entered for Analysis II.',
      postIds: const ['debug-post-2'],
    ),
    InboxMessage(
      id: 'debug-msg-3',
      sender: 'Instructor · Kovacs',
      subject: 'Consultation on Thursday',
      sentAt: today.subtract(Duration(days: today.weekday + 6)),
      unread: false,
      preview: 'Office hours this week are in D 3-510.',
      postIds: const ['debug-post-3'],
    ),
  ];
}

List<InboxPost> debugInboxPosts(String messageId, DateTime now) {
  return switch (messageId) {
    'debug-msg-1' => [
        InboxPost(
          id: 'debug-post-1',
          sender: 'Registrar',
          body:
              'The spring exam period dates are now in Neptun. Check Study for signup windows.',
          sentAt: DateTime(now.year, now.month, now.day, 14, 2),
        ),
      ],
    'debug-msg-2' => [
        InboxPost(
          id: 'debug-post-2',
          sender: 'Neptun',
          body: 'A new result was entered for Analysis II (4).',
          sentAt: now.subtract(const Duration(days: 1)),
        ),
      ],
    _ => [
        InboxPost(
          id: 'debug-post-3',
          sender: 'Instructor · Kovacs',
          body: 'Office hours this week are in D 3-510 after the lecture.',
          sentAt: now.subtract(const Duration(days: 3)),
        ),
      ],
  };
}
