// Basic smoke test for the Learning App shell.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('LearningApp builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const LearningApp());
    await tester.pumpAndSettle();

    expect(find.byType(LearningApp), findsOneWidget);
  });
}
