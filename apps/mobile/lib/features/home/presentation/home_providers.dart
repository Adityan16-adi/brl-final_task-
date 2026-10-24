import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/network_providers.dart';
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
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) => state = mode;

  void cycle() {
    state = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
