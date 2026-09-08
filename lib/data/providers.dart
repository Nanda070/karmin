import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:karmin/api/neptun_student_api.dart';
import 'package:karmin/auth/auth_models.dart';
import 'package:karmin/auth/providers.dart';
import 'package:karmin/data/cache_store.dart';
import 'package:karmin/data/prefs_cache_store.dart';
import 'package:karmin/data/student_repository.dart';

final cacheStoreProvider = Provider<CacheStore>((ref) {
  return PrefsCacheStore();
});

final neptunStudentApiProvider = Provider<NeptunStudentApi>((ref) {
  if (ref.watch(debugAuthFlagProvider)) {
    return DebugNeptunStudentApi();
  }
  return LiveNeptunStudentApi(ref.watch(neptunClientProvider));
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(
    api: ref.watch(neptunStudentApiProvider),
    cache: ref.watch(cacheStoreProvider),
  );
});

final studentSnapshotProvider =
    AsyncNotifierProvider<StudentSnapshotNotifier, StudentSnapshot>(
  StudentSnapshotNotifier.new,
);

class StudentSnapshotNotifier extends AsyncNotifier<StudentSnapshot> {
  @override
  Future<StudentSnapshot> build() async {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.hasCredentials == true && !next.hasCredentials) {
        ref.read(studentRepositoryProvider).clear();
      }
    });

    final auth = ref.watch(authControllerProvider);
    if (!auth.hasLiveJwt) {
      final cached = await ref.read(studentRepositoryProvider).readCache();
      return cached ?? StudentSnapshot.empty();
    }
    return ref.read(studentRepositoryProvider).load();
  }

  Future<void> refresh() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.hasLiveJwt) {
      return;
    }
    state = AsyncData(
      await ref.read(studentRepositoryProvider).load(force: true),
    );
  }
}
