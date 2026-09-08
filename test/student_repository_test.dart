import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/api/dtos/calendar_event.dart';
import 'package:karmin/api/dtos/exam_offer.dart';
import 'package:karmin/api/dtos/inbox_message.dart';
import 'package:karmin/api/dtos/student_profile.dart';
import 'package:karmin/api/dtos/taken_subject.dart';
import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_student_api.dart';
import 'package:karmin/data/cache_store.dart';
import 'package:karmin/data/student_repository.dart';

class FailingStudentApi implements NeptunStudentApi {
  @override
  Future<List<CalendarEvent>> getCalendarEvents({
    required DateTime start,
    required DateTime end,
  }) async {
    throw const NeptunNetworkException();
  }

  @override
  Future<double?> getDashboardAverages() async {
    throw const NeptunNetworkException();
  }

  @override
  Future<({int? completed, int? required})> getDashboardCreditProgress() async {
    throw const NeptunNetworkException();
  }

  @override
  Future<int> getUnreadMessageCount() async {
    throw const NeptunNetworkException();
  }

  @override
  Future<StudentProfile> getUserInfo() async {
    throw const NeptunNetworkException();
  }

  @override
  Future<String?> getTrainingLabel() async {
    throw const NeptunNetworkException();
  }

  @override
  Future<List<TakenSubject>> getTakenSubjects() async {
    throw const NeptunNetworkException();
  }

  @override
  Future<List<ExamOffer>> getExamOffers() async {
    throw const NeptunNetworkException();
  }

  @override
  Future<List<ExamOffer>> getExamsForSubject({
    required String subjectId,
    required String termId,
  }) async {
    throw const NeptunNetworkException();
  }

  @override
  Future<ExamSignupResult> signUpForExam(String examId) async {
    throw const NeptunNetworkException();
  }

  @override
  Future<List<InboxMessage>> getReceivedMessages() async {
    throw const NeptunNetworkException();
  }

  @override
  Future<List<InboxPost>> getMessagePosts(String messageId) async {
    throw const NeptunNetworkException();
  }

  @override
  Future<void> markMessageRead({
    required String messageId,
    required List<String> postIds,
  }) async {
    throw const NeptunNetworkException();
  }
}

void main() {
  test('debug snapshot caches and survives a later network failure', () async {
    final cache = MemoryCacheStore();
    final repo = StudentRepository(
      api: DebugNeptunStudentApi(clock: () => DateTime(2026, 9, 8, 7, 30)),
      cache: cache,
      clock: () => DateTime(2026, 9, 8, 7, 30),
    );

    final first = await repo.refresh();
    expect(first.events, isNotEmpty);
    expect(first.subjects, isNotEmpty);
    expect(first.messages, isNotEmpty);
    expect(first.dashboard.gpa, 4.32);
    expect(first.fromCache, isFalse);
    expect(cache.data[StudentRepository.cacheKey], isNotEmpty);

    final failing = StudentRepository(
      api: FailingStudentApi(),
      cache: cache,
      clock: () => DateTime(2026, 9, 8, 7, 31),
    );
    final second = await failing.refresh();
    expect(second.fromCache, isTrue);
    expect(second.events, isNotEmpty);
    expect(second.subjects, isNotEmpty);
    expect(second.messages, isNotEmpty);
    expect(second.errorMessage, const NeptunNetworkException().message);
  });

  test('empty snapshot when refresh fails with no cache', () async {
    final repo = StudentRepository(
      api: FailingStudentApi(),
      cache: MemoryCacheStore(),
      clock: () => DateTime(2026, 9, 8),
    );
    final snapshot = await repo.refresh();
    expect(snapshot.subjects, isEmpty);
    expect(snapshot.messages, isEmpty);
    expect(snapshot.errorMessage, const NeptunNetworkException().message);
  });

  test('marking a message read keeps Today unread count in sync', () async {
    final repo = StudentRepository(
      api: DebugNeptunStudentApi(clock: () => DateTime(2026, 9, 8, 14, 2)),
      cache: MemoryCacheStore(),
      clock: () => DateTime(2026, 9, 8, 14, 2),
    );
    final first = await repo.refresh();
    expect(first.unreadCount, 2);
    final after = await repo.markMessageRead('debug-msg-1');
    expect(after.unreadCount, 1);
    expect(after.dashboard.unreadCount, 1);
    expect(after.messageById('debug-msg-1')?.unread, isFalse);
  });

  test('debug exam signup is labeled and not a fake live success', () async {
    final repo = StudentRepository(
      api: DebugNeptunStudentApi(clock: () => DateTime(2026, 9, 8)),
      cache: MemoryCacheStore(),
      clock: () => DateTime(2026, 9, 8),
    );
    await repo.refresh();
    final outcome = await repo.signUpForExam('debug-exam-1');
    expect(outcome.result.accepted, isTrue);
    expect(outcome.result.message, contains('debug'));
    expect(outcome.snapshot.signupExam?.signedUp, isTrue);
  });
}
