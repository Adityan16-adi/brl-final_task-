import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/branding/app_branding.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/mock_auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';
import 'package:mobile/features/auth/presentation/register_screen.dart';
import 'package:mobile/features/auth/presentation/welcome_screen.dart';
import 'package:mobile/features/auth/presentation/widgets/google_sign_in_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp(Widget child, {MockAuthRepository? repo}) {
    final mockRepo = repo ?? MockAuthRepository();
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: child),
      ),
    );
  }

  group('Step 10: Google Sign-In & Role Selection Tests', () {
    testWidgets('GoogleSignInButton renders on LoginScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('GoogleSignInButton renders on RegisterScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Sign up with Google'), findsOneWidget);
    });

    testWidgets('GoogleSignInButton renders on WelcomeScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(const WelcomeScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('Google unavailable dialog explains missing services and affirms email/demo login', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showGoogleUnavailableDialog(
                context,
                'Google Sign-In is unavailable on this device (google-services.json is missing or not configured). Please sign in using Email & Password or use Demo Mode.',
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Google Sign-In Notice'), findsOneWidget);
      expect(find.textContaining('google-services.json is missing'), findsOneWidget);
      expect(find.textContaining('Email/Password login and Demo Mode are fully operational.'), findsOneWidget);
      expect(find.text('OK, Got It'), findsOneWidget);

      await tester.tap(find.text('OK, Got It'));
      await tester.pumpAndSettle();
      expect(find.text('Google Sign-In Notice'), findsNothing);
    });

    testWidgets('showRoleSelectionSheet allows student and teacher selection with teacher code field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => showRoleSelectionSheet(
                  context,
                  ref,
                  const GoogleAuthResult(
                    needsRoleSelection: true,
                    email: 'newuser@google.com',
                    idToken: 'mock-id-token',
                  ),
                  null,
                ),
                child: const Text('Trigger Role Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Role Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to ${AppBranding.appName}!'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Teacher'), findsOneWidget);
      expect(find.text('Complete Sign In'), findsOneWidget);

      // Tap Teacher role
      await tester.tap(find.text('Teacher'));
      await tester.pumpAndSettle();

      expect(find.text('Teacher Provisioning Code'), findsOneWidget);

      // Tap Student role again
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();

      // Teacher code field disappears
      expect(find.text('Teacher Provisioning Code'), findsNothing);
    });
  });
}
