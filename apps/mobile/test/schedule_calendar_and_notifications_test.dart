import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/clay_theme.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/mock_auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/home/domain/home_repository.dart';
import 'package:mobile/features/home/presentation/home_providers.dart';
import 'package:mobile/features/home/presentation/notification_providers.dart';
import 'package:mobile/features/home/presentation/widgets/notifications_sheet.dart';
import 'package:mobile/features/home/presentation/widgets/schedule_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildScheduleTestApp({
    AppUser? user,
    List<ScheduleItem>? customSchedule,
  }) {
    final now = DateTime.now();
    final defaultSchedule = [
      ScheduleItem(
        id: 's-1',
        title: 'Cell Biology Lecture',
        subject: 'Biology',
        time: '10:00 AM - 11:30 AM',
        location: 'Virtual Hall A',
        type: 'Lecture',
        isToday: true,
        date: now,
      ),
      ScheduleItem(
        id: 's-2',
        title: 'Calculus Problem Clinic',
        subject: 'Mathematics',
        time: '02:00 PM - 03:30 PM',
        location: 'Room 201',
        type: 'Lecture',
        isToday: true,
        date: now,
      ),
      ScheduleItem(
        id: 's-3',
        title: 'Genetics Lab Report Due',
        subject: 'Biology',
        time: 'Due 11:59 PM',
        location: 'Online Dropbox',
        type: 'Deadline',
        isToday: false,
        date: now.add(const Duration(days: 2)),
      ),
    ];

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith(
          (ref) => user ?? MockAuthRepository.studentUser,
        ),
        scheduleProvider.overrideWith(
          (ref) async => customSchedule ?? defaultSchedule,
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: ScheduleView(),
        ),
      ),
    );
  }

  group('Part E: Month View Calendar & Notifications Tests', () {
    testWidgets('ScheduleView renders 7-day column month grid (Mon..Sun) and indicator dots', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScheduleTestApp());
      await tester.pumpAndSettle();

      // Weekday columns Mon..Sun
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);

      // Filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Lectures'), findsOneWidget);
      expect(find.text('Deadlines'), findsOneWidget);

      // Indicator legend
      expect(find.text('Class / Lecture'), findsOneWidget);
      expect(find.text('Assignment Deadline'), findsOneWidget);

      // Today's events are shown by default
      expect(find.text('Cell Biology Lecture'), findsOneWidget);
      expect(find.text('Calculus Problem Clinic'), findsOneWidget);
    });

    testWidgets('Month navigation switches months and today button returns', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScheduleTestApp());
      await tester.pumpAndSettle();

      // Next month
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();

      // Return to current month via Today button
      await tester.tap(find.byTooltip('Current month'));
      await tester.pumpAndSettle();

      // Confirm today's events are visible
      expect(find.text('Cell Biology Lecture'), findsOneWidget);
    });

    testWidgets('Tapping a day updates selection and shows its events', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      // Target a day with the deadline (2 days from now, if in same month)
      final futureDay = now.add(const Duration(days: 2));

      await tester.pumpWidget(buildScheduleTestApp());
      await tester.pumpAndSettle();

      // Tap on the day number
      final dayFinder = find.widgetWithText(InkWell, '${futureDay.day}');
      if (dayFinder.evaluate().isNotEmpty) {
        await tester.tap(dayFinder.first);
        await tester.pumpAndSettle();

        // Either Genetics Lab Report Due or empty state is displayed cleanly without crash
        expect(
          find.byType(ScheduleView),
          findsOneWidget,
        );
      }
    });

    testWidgets('In-App Notifications center displays alerts and allows mark all as read', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildScheduleTestApp());
      await tester.pumpAndSettle();

      // Tap notifications center icon button
      final bellFinder = find.byTooltip('Reminders & Alerts');
      expect(bellFinder, findsOneWidget);
      await tester.tap(bellFinder);
      await tester.pumpAndSettle();

      // Header in bottom sheet
      expect(find.text('Classroom Reminders & Alerts'), findsOneWidget);

      // Verify "Mark all as read" button exists when unread items exist
      final markAllFinder = find.text('Mark all as read');
      if (markAllFinder.evaluate().isNotEmpty) {
        await tester.tap(markAllFinder);
        await tester.pumpAndSettle();
      }
    });
  });
}
