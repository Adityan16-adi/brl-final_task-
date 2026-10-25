import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/mock_auth_repository.dart';
import 'package:mobile/features/home/data/home_repository_impl.dart';
import 'package:mobile/features/home/domain/home_repository.dart';
import 'package:mobile/features/home/presentation/home_providers.dart';
import 'package:mobile/features/home/presentation/widgets/materials_view.dart';
import 'package:mobile/features/home/presentation/widgets/submit_assignment_dialog.dart';
import 'package:mobile/features/home/presentation/widgets/upload_material_dialog.dart';

void _setDimensions(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part 3: File & Photo Attachments UI Tests', () {
    testWidgets(
      'SubmitAssignmentDialog renders attachment actions (Add Document, Camera, Gallery)',
      (tester) async {
        _setDimensions(tester);

        const testAssign = AssignmentItem(
          id: 'assign-upload-test',
          title: 'Quantum Harmonic Oscillator',
          subject: 'Physics',
          dueDate: 'Tomorrow',
          points: 30,
          status: AssignmentStatus.pending,
          description: 'Calculate eigenvalue solutions.',
        );

        final authRepo = MockAuthRepository(
          initialUser: MockAuthRepository.studentUser,
        );
        final inMemoryRepo = InMemoryHomeRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(authRepo),
              homeRepositoryProvider.overrideWithValue(inMemoryRepo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SubmitAssignmentDialog(assignment: testAssign),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check header, fields and buttons
        expect(find.text('Quantum Harmonic Oscillator'), findsOneWidget);
        expect(find.text('Add Document'), findsOneWidget);
        expect(find.text('Camera'), findsOneWidget);
        expect(find.text('Gallery'), findsOneWidget);
        expect(
          find.text('Attach Files or Photos (Max 25MB)'),
          findsOneWidget,
        );
        expect(
          find.text('Submission Attachment / Document Link (Optional)'),
          findsOneWidget,
        );
        expect(find.text('Turn In'), findsOneWidget);
      },
    );

    testWidgets(
      'SubmitAssignmentDialog displays existing attachments when present',
      (tester) async {
        _setDimensions(tester);

        const testAssignWithAtt = AssignmentItem(
          id: 'assign-existing-att',
          title: 'Linear Algebra Matrix Inversion',
          subject: 'Mathematics',
          dueDate: 'Yesterday',
          points: 20,
          status: AssignmentStatus.submitted,
          submittedText: 'Computed Gaussian elimination solutions.',
          attachments: [
            SubmissionAttachment(
              url: 'https://storage.googleapis.com/demo/solution_proof.pdf',
              name: 'solution_proof.pdf',
              size: 245000,
            ),
          ],
        );

        final authRepo = MockAuthRepository(
          initialUser: MockAuthRepository.studentUser,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(authRepo),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SubmitAssignmentDialog(assignment: testAssignWithAtt),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Existing Attached Files'), findsOneWidget);
        expect(find.text('solution_proof.pdf'), findsOneWidget);
        expect(find.text('Update Submission'), findsOneWidget);
      },
    );

    testWidgets(
      'UploadMaterialDialog offers Choose File from Device button and category chips',
      (tester) async {
        _setDimensions(tester);

        final authRepo = MockAuthRepository(
          initialUser: MockAuthRepository.teacherUser,
        );
        final inMemoryRepo = InMemoryHomeRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(authRepo),
              homeRepositoryProvider.overrideWithValue(inMemoryRepo),
            ],
            child: const MaterialApp(
              home: Scaffold(body: UploadMaterialDialog()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Upload Study Material'), findsOneWidget);
        expect(find.text('Material Title *'), findsOneWidget);
        expect(find.text('Subject / Course *'), findsOneWidget);
        expect(find.text('Choose File from Device'), findsOneWidget);
        expect(find.text('Publish Study Material'), findsOneWidget);
      },
    );

    testWidgets(
      'MaterialsView opens sheet and shows Access Material Resource button',
      (tester) async {
        _setDimensions(tester);

        final authRepo = MockAuthRepository(
          initialUser: MockAuthRepository.studentUser,
        );
        final inMemoryRepo = InMemoryHomeRepository();

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

        // Tap the first material card to view resource details
        final firstCard = find.byType(MaterialsView);
        expect(firstCard, findsOneWidget);

        // Find a material tile
        final materialTitle = find.text('Eukaryotic Cell Architecture Slide Deck');
        expect(materialTitle, findsOneWidget);

        await tester.tap(materialTitle);
        await tester.pumpAndSettle();

        expect(find.text('Access Material Resource'), findsOneWidget);
      },
    );
  });
}
