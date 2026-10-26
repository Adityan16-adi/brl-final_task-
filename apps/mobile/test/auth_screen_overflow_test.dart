import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';
import 'package:mobile/features/auth/presentation/register_screen.dart';
import 'package:mobile/features/auth/presentation/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget(Widget child, {Size size = const Size(360, 640)}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Auth Screens Overflow Tests at 360px and 320px width', () {
    testWidgets('LoginScreen renders without overflow at 360x640', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(const LoginScreen(), size: const Size(360, 640)));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Try demo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LoginScreen renders without overflow at narrow 320x568', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(const LoginScreen(), size: const Size(320, 568)));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('WelcomeScreen renders without overflow at 360x640', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(const WelcomeScreen(), size: const Size(360, 640)));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('WelcomeScreen renders without overflow at narrow 320x568', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(const WelcomeScreen(), size: const Size(320, 568)));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RegisterScreen renders without overflow at 360x640', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(const RegisterScreen(), size: const Size(360, 640)));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RegisterScreen renders without overflow at narrow 320x568', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWidget(const RegisterScreen(), size: const Size(320, 568)));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
