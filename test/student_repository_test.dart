import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/api/dtos/calendar_event.dart';
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
    expect(second.errorMessage, const NeptunNetworkException().message);
  });
}
