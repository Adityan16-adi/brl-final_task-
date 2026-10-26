import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/branding/app_branding.dart';
import 'package:mobile/core/providers/network_providers.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/mock_auth_repository.dart';
import 'package:mobile/features/auth/data/persistent_auth_repository.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';
import 'package:mobile/features/auth/presentation/splash_screen.dart';
import 'package:mobile/features/auth/presentation/welcome_screen.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Part B: Session, Splash, and Welcome Screen Tests', () {
    testWidgets('SplashScreen renders centered logo tile and app branding', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SplashScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(AppBranding.appName), findsOneWidget);
      expect(find.text(AppBranding.tagline), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Valid session in SharedPreferences recovers straight to Dashboard without flashing Welcome', (tester) async {
      final userJson = jsonEncode(MockAuthRepository.studentUser.toJson());
      SharedPreferences.setMockInitialValues({
        PersistentAuthRepository.keyUser: userJson,
        PersistentAuthRepository.keyToken: 'mock-valid-jwt-token',
        PersistentAuthRepository.keyOnboarding: true,
      });

      final prefs = await SharedPreferences.getInstance();
      final repo = PersistentAuthRepository(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: const LearningApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Confirms user is directly on Dashboard Overview
      expect(find.text('Dashboard Overview'), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('Sign out clears the active token and navigates directly to WelcomeScreen', (tester) async {
      final userJson = jsonEncode(MockAuthRepository.studentUser.toJson());
      SharedPreferences.setMockInitialValues({
        PersistentAuthRepository.keyUser: userJson,
        PersistentAuthRepository.keyToken: 'active-session-token',
        PersistentAuthRepository.keyOnboarding: true,
      });

      final prefs = await SharedPreferences.getInstance();
      final repo = PersistentAuthRepository(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: const LearningApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Overview'), findsOneWidget);

      // Perform sign out
      await repo.signOut();
      await tester.pumpAndSettle();

      // Confirms user is now on WelcomeScreen
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.textContaining('Sign in'), findsWidgets);
    });

    testWidgets('401 session expiration displays friendly message on LoginScreen', (tester) async {
      late ProviderContainer container;

      final testWidget = UncontrolledProviderScope(
        container: container = ProviderContainer(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const LoginScreen(),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Initially no session expired banner
      expect(find.text('Session expired, please sign in again'), findsNothing);

      // Trigger session expired message
      container
          .read(sessionExpiredMessageProvider.notifier)
          .setMessage('Session expired, please sign in again');
      await tester.pumpAndSettle();

      // Friendly message is now visible on LoginScreen
      expect(find.text('Session expired, please sign in again'), findsOneWidget);
    });

    testWidgets('Network unreachable error displays top banner without logging user out', (tester) async {
      final user = MockAuthRepository.studentUser;

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(user),
        ],
      );

      final testWidget = UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const HomeScreen(),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Initially no offline banner
      expect(find.text("Can't reach the server. Working offline."), findsNothing);

      // Trigger server unreachable state
      container
          .read(serverUnreachableProvider.notifier)
          .setUnreachable(true);
      await tester.pumpAndSettle();

      // Top banner is visible with Retry button
      expect(find.text("Can't reach the server. Working offline."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // User session remains intact
      expect(find.text('Dashboard Overview'), findsOneWidget);
    });
  });
}
