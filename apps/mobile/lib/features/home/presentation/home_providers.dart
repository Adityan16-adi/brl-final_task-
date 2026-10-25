import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/network_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/home_repository_impl.dart';
import '../data/http_home_repository.dart';
import '../domain/home_repository.dart';

bool get _isFlutterTest {
  if (kIsWeb) return false;
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  if (_isFlutterTest) {
    return InMemoryHomeRepository();
  }
  final dio = ref.watch(coreDioProvider);
  return HttpHomeRepository(dio: dio);
});

final homeSummaryProvider = FutureProvider.autoDispose<HomeSummary>((
  ref,
) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getSummary();
});

final classroomsProvider = FutureProvider.autoDispose<List<ClassroomItem>>((
  ref,
) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getClassrooms();
});

final assignmentsProvider = FutureProvider.autoDispose<List<AssignmentItem>>((
  ref,
) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getAssignments();
});

final materialsProvider = FutureProvider.autoDispose<List<MaterialItem>>((
  ref,
) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getMaterials();
});

final scheduleProvider = FutureProvider.autoDispose<List<ScheduleItem>>((
  ref,
) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getSchedule();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'app_theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs?.getString(_key);
    if (saved == 'light') return ThemeMode.light;
    if (saved == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs != null) {
      if (mode == ThemeMode.light) {
        prefs.setString(_key, 'light');
      } else if (mode == ThemeMode.dark) {
        prefs.setString(_key, 'dark');
      } else {
        prefs.remove(_key);
      }
    }
  }

  void cycle() {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    setThemeMode(next);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

final classroomAttendanceProvider =
    FutureProvider.family.autoDispose<List<AttendanceSession>, String>((
  ref,
  classId,
) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getClassAttendance(classId);
});

final studentAttendanceSummaryProvider =
    FutureProvider.family.autoDispose<StudentAttendanceSummary, String>((
  ref,
  studentUid,
) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getStudentAttendance(studentUid);
});

