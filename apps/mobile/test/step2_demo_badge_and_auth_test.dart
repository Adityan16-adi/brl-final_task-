import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/demo_data_badge.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/presentation/welcome_screen.dart';
import 'package:mobile/features/home/presentation/widgets/materials_view.dart';
import 'package:mobile/features/home/presentation/widgets/overview_view.dart';
import 'package:mobile/features/home/presentation/widgets/schedule_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp(Widget child, {AppUser? user}) {
    return ProviderScope(
      overrides: [
        if (user != null) currentUserProvider.overrideWithValue(user),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: child),
      ),
    );
  }

  group('Step 2: Demo Mode & Demo Data Badge Tests', () {
    testWidgets('WelcomeScreen has explicit Explore in Demo Mode button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildApp(const WelcomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Explore in Demo Mode (Offline)'), findsOneWidget);
    });

    testWidgets('OverviewView displays DemoDataBadge when in demo mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const demoUser = AppUser(
        uid: 'demo-student',
        email: 'student@demo.com',
        name: 'Demo Student',
        role: UserRole.student,
        isDemo: true,
      );

      await tester.pumpWidget(buildApp(OverviewView(onNavigateToTab: (_) {}), user: demoUser));
      await tester.pumpAndSettle();

      expect(find.text('DEMO DATA'), findsOneWidget);
    });

    testWidgets('MaterialsView displays DemoDataBadge for fallback/demo dataset', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const demoUser = AppUser(
        uid: 'demo-student',
        email: 'student@demo.com',
        name: 'Demo Student',
        role: UserRole.student,
        isDemo: true,
      );

      await tester.pumpWidget(buildApp(const MaterialsView(), user: demoUser));
      await tester.pumpAndSettle();

      expect(find.byType(DemoDataBadge), findsOneWidget);
    });

    testWidgets('ScheduleView displays DemoDataBadge for fallback/demo dataset', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const demoUser = AppUser(
        uid: 'demo-student',
        email: 'student@demo.com',
        name: 'Demo Student',
        role: UserRole.student,
        isDemo: true,
      );

      await tester.pumpWidget(buildApp(const ScheduleView(), user: demoUser));
      await tester.pumpAndSettle();

      expect(find.byType(DemoDataBadge), findsOneWidget);
    });
  });
}
