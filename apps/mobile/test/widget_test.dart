
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('app opens on the learning overview', (tester) async {
    await tester.pumpWidget(const LearningApp());

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Your learning space'), findsOneWidget);
    expect(find.text('Your workspace'), findsOneWidget);
    expect(find.text('Make every learning day count.'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('drawer navigation opens the assignments section',
      (tester) async {
    await tester.pumpWidget(const LearningApp());

    // Open the navigation drawer.
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('Assignments'), findsWidgets);

    // Select Assignments from the drawer.
    await tester.tap(find.text('Assignments').last);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This section is part of the app shell. '
        'Its data and actions will be added in later phases.',
      ),
      findsOneWidget,
    );
    expect(find.text('Back to overview'), findsOneWidget);
  });

  testWidgets('app supports light and dark themes with system mode by default',
      (tester) async {
    await tester.pumpWidget(const LearningApp());

    final app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );

    expect(app.theme, isNotNull);
    expect(app.darkTheme, isNotNull);
    expect(app.themeMode, ThemeMode.system);
  });
}
