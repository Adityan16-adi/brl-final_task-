import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/home_repository.dart';
import 'home_providers.dart';

enum NotificationType {
  classReminder,
  assignmentDue,
  newGrade,
  announcement,
}

class InAppNotificationItem {
  const InAppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;

  InAppNotificationItem copyWith({bool? isRead}) {
    return InAppNotificationItem(
      id: id,
      title: title,
      body: body,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

const String _keyLastReadTs = 'notifications_last_read_ts';

class NotificationsNotifier extends AsyncNotifier<List<InAppNotificationItem>> {
  @override
  Future<List<InAppNotificationItem>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReadTs = prefs.getInt(_keyLastReadTs) ?? 0;

    final classroomsAsync = ref.watch(classroomsProvider);
    final assignmentsAsync = ref.watch(assignmentsProvider);

    final classrooms = classroomsAsync.value ?? [];
    final assignments = assignmentsAsync.value ?? [];

    final list = <InAppNotificationItem>[];
    final now = DateTime.now();

    // 1. Upcoming class notification
    if (classrooms.isNotEmpty) {
      final c = classrooms.first;
      final ts = now.subtract(const Duration(minutes: 25));
      list.add(
        InAppNotificationItem(
          id: 'notif-class-${c.id}',
          title: 'Class Reminder: ${c.name}',
          body: '${c.subject} scheduled for ${c.schedule.isNotEmpty ? c.schedule : "today"}. Tap to join.',
          type: NotificationType.classReminder,
          timestamp: ts,
          isRead: ts.millisecondsSinceEpoch <= lastReadTs,
        ),
      );
    }

    // 2. Assignment due soon notification
    final pending = assignments.where((a) => a.status == AssignmentStatus.pending).toList();
    if (pending.isNotEmpty) {
      final a = pending.first;
      final ts = now.subtract(const Duration(hours: 2));
      list.add(
        InAppNotificationItem(
          id: 'notif-assign-${a.id}',
          title: 'Assignment Due Soon',
          body: '"${a.title}" for ${a.subject} is due ${a.dueDate}.',
          type: NotificationType.assignmentDue,
          timestamp: ts,
          isRead: ts.millisecondsSinceEpoch <= lastReadTs,
        ),
      );
    }

    // 3. Graded assignment notification
    final graded = assignments.where((a) => a.status == AssignmentStatus.graded).toList();
    if (graded.isNotEmpty) {
      final g = graded.first;
      final ts = now.subtract(const Duration(days: 1));
      list.add(
        InAppNotificationItem(
          id: 'notif-grade-${g.id}',
          title: 'Assignment Graded',
          body: 'Your submission for "${g.title}" received ${g.points} points.',
          type: NotificationType.newGrade,
          timestamp: ts,
          isRead: ts.millisecondsSinceEpoch <= lastReadTs,
        ),
      );
    }

    // 4. Welcome announcement
    final welcomeTs = now.subtract(const Duration(days: 2));
    list.add(
      InAppNotificationItem(
        id: 'notif-system-welcome',
        title: 'Welcome to Pragti',
        body: 'Learn · Connect · Grow. Manage classes, submissions, and live learning seamlessly.',
        type: NotificationType.announcement,
        timestamp: welcomeTs,
        isRead: welcomeTs.millisecondsSinceEpoch <= lastReadTs,
      ),
    );

    return list;
  }

  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastReadTs, DateTime.now().millisecondsSinceEpoch);

    final current = state.value ?? [];
    state = AsyncData(current.map((n) => n.copyWith(isRead: true)).toList());
  }
}

final inAppNotificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<InAppNotificationItem>>(
  NotificationsNotifier.new,
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(inAppNotificationsProvider).value ?? [];
  return notifs.where((n) => !n.isRead).length;
});
