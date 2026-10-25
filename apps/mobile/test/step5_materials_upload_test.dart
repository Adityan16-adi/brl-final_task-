import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/mock_auth_repository.dart';
import 'package:mobile/features/home/data/home_repository_impl.dart';
import 'package:mobile/features/home/domain/home_repository.dart';
import 'package:mobile/features/home/presentation/home_providers.dart';
import 'package:mobile/features/home/presentation/widgets/materials_view.dart';
import 'package:mobile/features/home/presentation/widgets/upload_material_dialog.dart';

void _setDimensions(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Step 5: Materials Upload Repository Unit Tests', () {
    test('uploadMaterial stores material with thumbnail and category', () async {
      final repo = InMemoryHomeRepository();

      final created = await repo.uploadMaterial(
        classId: 'class-astro',
        title: 'Neutron Stars and Pulsars Lecture',
        subject: 'Astrophysics',
        type: CourseMaterialType.video,
        details: 'Deep dive into stellar remnants with simulation models.',
        link: 'https://example.com/pulsars.mp4',
        thumbnailUrl: 'https://example.com/pulsars_thumb.jpg',
      );

      expect(created.title, 'Neutron Stars and Pulsars Lecture');
      expect(created.subject, 'Astrophysics');
      expect(created.type, CourseMaterialType.video);
      expect(created.thumbnailUrl, 'https://example.com/pulsars_thumb.jpg');

      final list = await repo.getMaterials();
      expect(list.any((m) => m.title == 'Neutron Stars and Pulsars Lecture'), isTrue);
    });
  });

  group('Step 5: Teacher Materials Upload UI Flow Tests', () {
    testWidgets('Teacher sees Upload Study Material button, fills dialog and publishes', (
      tester,
    ) async {
      _setDimensions(tester);

      final inMemoryRepo = InMemoryHomeRepository();
      final authRepo = MockAuthRepository(
        initialUser: MockAuthRepository.teacherUser,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
            homeRepositoryProvider.overrideWithValue(inMemoryRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MaterialsView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Teacher sees Upload button
      expect(find.text('Upload Study Material'), findsOneWidget);

      // Tap Upload button to open dialog
      await tester.tap(find.text('Upload Study Material'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.byType(UploadMaterialDialog), findsOneWidget);
      expect(find.text('Material Title *'), findsOneWidget);
      expect(find.text('Subject / Course *'), findsOneWidget);
      expect(find.text('Publish Study Material'), findsOneWidget);

      // Enter material details
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Material Title *'),
        'Quantum Field Theory Foundations',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Subject / Course *'),
        'Physics',
      );

      // Select Video format chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Video'));
      await tester.pumpAndSettle();

      // Enter resource link
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Resource / Document Link'),
        'https://example.com/qft.pdf',
      );

      // Submit form
      await tester.tap(find.text('Publish Study Material'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.byType(UploadMaterialDialog), findsNothing);
      expect(find.text('Study material published successfully!'), findsOneWidget);

      // Newly uploaded material is visible in the list
      expect(find.text('Quantum Field Theory Foundations'), findsOneWidget);
    });
  });

  group('Step 5: Student View Tests', () {
    testWidgets('Student does not see Upload button and can filter materials', (
      tester,
    ) async {
      _setDimensions(tester);

      final inMemoryRepo = InMemoryHomeRepository();
      final authRepo = MockAuthRepository(
        initialUser: MockAuthRepository.studentUser,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
            homeRepositoryProvider.overrideWithValue(inMemoryRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MaterialsView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Student does NOT see Upload Study Material button
      expect(find.text('Upload Study Material'), findsNothing);

      // Filter chips are accessible
      expect(find.text('All Types'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);

      // Tap Videos chip
      await tester.ensureVisible(find.text('Videos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Videos'));
      await tester.pumpAndSettle();

      // Chain Rule video is displayed
      expect(find.text('Chain Rule & Quotient Rule Walkthrough'), findsOneWidget);
      // Slides notes should be filtered out
      expect(find.text('Eukaryotic Cell Architecture Slide Deck'), findsNothing);
    });
  });
}
