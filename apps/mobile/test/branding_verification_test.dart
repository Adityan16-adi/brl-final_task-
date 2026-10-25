import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/branding/app_branding.dart';
import 'package:mobile/core/branding/brand_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/clay_theme.dart';
import 'package:mobile/features/auth/presentation/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Part 1: Pragti Branding Verification Tests', () {
    test('AppBranding centralizes official appName and tagline', () {
      expect(AppBranding.appName, equals('Pragti'));
      expect(AppBranding.tagline, equals('Learn · Connect · Grow'));
      expect(AppBranding.logoOriginal, contains('pragti_logo_original'));
      expect(AppBranding.logoTransparent, contains('pragti_logo_transparent'));
      expect(AppBranding.mark, contains('pragti_mark'));
      expect(AppBranding.appIcon, contains('app_icon'));
    });

    test('ClayTokens and AppTheme align colors with Pragti logo palette', () {
      expect(ClayTokens.pragtiNavy, equals(const Color(0xFF0B1E48)));
      expect(ClayTokens.pragtiBlue, equals(const Color(0xFF1680ED)));
      expect(ClayTokens.pragtiOrange, equals(const Color(0xFFFB9823)));
      expect(ClayTokens.pragtiStar, equals(const Color(0xFFFBB746)));

      final light = AppTheme.light;
      expect(light.colorScheme.primary, equals(ClayTokens.pragtiBlue));
      expect(light.colorScheme.tertiary, equals(ClayTokens.pragtiOrange));

      final dark = AppTheme.dark;
      expect(dark.colorScheme.tertiary, equals(ClayTokens.pragtiOrange));
    });

    testWidgets('WelcomeScreen renders Pragti logo, name, and tagline', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify BrandHeader is present
      expect(find.byType(BrandHeader), findsOneWidget);

      // Verify official app name "Pragti"
      expect(find.text('Pragti'), findsOneWidget);

      // Verify official tagline "Learn · Connect · Grow"
      expect(find.text('Learn · Connect · Grow'), findsOneWidget);

      // Verify Mark image asset is loaded inside BrandLogo
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('BrandLogo renders on light and dark surfaces without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: Center(
              child: BrandLogo(
                size: 80,
                useMarkOnly: true,
                onCard: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrandLogo), findsOneWidget);
      expect(find.byType(ClayContainer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
