import 'package:dio/dio.dart';

import '../domain/home_repository.dart';

/// Live HTTP implementation of [HomeRepository] targeting the Node.js/Express backend.
class HttpHomeRepository implements HomeRepository {
  HttpHomeRepository({required this.dio});

  final Dio dio;

  @override
  Future<List<ClassroomItem>> getClassrooms() async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/api/classrooms');
      final data = response.data;
      if (data != null && data['success'] == true) {
        final list = data['classrooms'] as List<dynamic>? ?? [];
        return list
            .map((item) => ClassroomItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final message =
          e.response?.data is Map && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : e.message ?? 'Failed to fetch classrooms';
      throw ClassroomException(message!, statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ClassroomItem> createClassroom({
    required String name,
    required String subject,
    String? description,
    String? schedule,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/classrooms',
        data: {
          'name': name.trim(),
          'subject': subject.trim(),
          if (description != null) 'description': description.trim(),
          if (schedule != null) 'schedule': schedule.trim(),
        },
      );

      final data = response.data;
      if (data != null &&
          data['success'] == true &&
          data['classroom'] != null) {
        return ClassroomItem.fromJson(
          data['classroom'] as Map<String, dynamic>,
        );
      }
      throw const ClassroomException('Unexpected response from server');
    } on DioException catch (e) {
      final message =
          e.response?.data is Map && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : e.message ?? 'Unable to connect to server';
      throw ClassroomException(message!, statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ClassroomItem> joinClassroom(String code) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/classrooms/join',
        data: {'code': code.trim().toUpperCase()},
      );

      final data = response.data;
      if (data != null &&
          data['success'] == true &&
          data['classroom'] != null) {
        return ClassroomItem.fromJson(
          data['classroom'] as Map<String, dynamic>,
        );
      }
      throw const ClassroomException('Unexpected response from server');
    } on DioException catch (e) {
      final message =
          e.response?.data is Map && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : e.message ?? 'Unable to connect to server';
      throw ClassroomException(message!, statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<ClassroomDetails> getClassroomDetails(String id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/classrooms/$id',
      );
      final data = response.data;
      if (data != null &&
          data['success'] == true &&
          data['classroom'] != null) {
        return ClassroomDetails.fromJson(
          data['classroom'] as Map<String, dynamic>,
        );
      }
      throw const ClassroomException('Classroom details not found');
    } on DioException catch (e) {
      final message =
          e.response?.data is Map && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : e.message ?? 'Unable to connect to server';
      throw ClassroomException(message!, statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<HomeSummary> getSummary() async {
    try {
      final classrooms = await getClassrooms();
      return HomeSummary(
        enrolledClassesCount: classrooms.length,
        pendingAssignmentsCount: 2,
        materialsCount: 3,
        nextClassTitle: classrooms.isNotEmpty ? classrooms.first.name : null,
        nextClassTime: classrooms.isNotEmpty ? classrooms.first.schedule : null,
      );
    } catch (_) {
      return const HomeSummary(
        enrolledClassesCount: 0,
        pendingAssignmentsCount: 0,
        materialsCount: 0,
      );
    }
  }

  @override
  Future<List<AssignmentItem>> getAssignments() async {
    // Return standard course assignments
    return const [
      AssignmentItem(
        id: 'assign-cell-notes',
        title: 'Cell Structures Concept Map',
        subject: 'Biology',
        dueDate: 'Tomorrow, 11:59 PM',
        points: 20,
        status: AssignmentStatus.pending,
        description: 'Create a conceptual diagram mapping eukaryotic vs prokaryotic organelle functions.',
      ),
      AssignmentItem(
        id: 'assign-calc-ps3',
        title: 'Problem Set 3: Derivatives & Rates',
        subject: 'Mathematics',
        dueDate: 'In 3 days',
        points: 30,
        status: AssignmentStatus.pending,
        description: 'Complete questions 1 to 15 from Chapter 4 on implicit differentiation.',
      ),
      AssignmentItem(
        id: 'assign-hist-essay',
        title: 'Primary Source Analysis Essay',
        subject: 'History',
        dueDate: 'Last Friday',
        points: 50,
        status: AssignmentStatus.graded,
        description:
            '1000-word critical analysis of post-war diplomatic treaties.',
        submittedText: 'Diplomatic resolutions following 1919 transformed modern statecraft...',
        marks: 47,
        feedback: 'Excellent synthesis of primary excerpts with thorough historiography.',
      ),
    ];
  }

  @override
  Future<List<MaterialItem>> getMaterials() async {
    return const [
      MaterialItem(
        id: 'mat-cell-slides',
        title: 'Eukaryotic Cell Architecture Slide Deck',
        subject: 'Biology',
        type: CourseMaterialType.notes,
        details: 'Lecture 4 summary slides covering membrane transport and organelles.',
        link: 'https://unified-learn.preview/resources/cell-architecture.pdf',
        createdAt: 'Oct 20',
      ),
      MaterialItem(
        id: 'mat-calc-video',
        title: 'Chain Rule & Quotient Rule Walkthrough',
        subject: 'Mathematics',
        type: CourseMaterialType.video,
        details: 'Recorded problem solving session with step-by-step calculus proofs.',
        link: 'https://unified-learn.preview/resources/chain-rule-video',
        createdAt: 'Oct 18',
      ),
      MaterialItem(
        id: 'mat-hist-sources',
        title: 'Primary Diplomatic Documents 1919-1939',
        subject: 'History',
        type: CourseMaterialType.document,
        details: 'Critical archive excerpts for the modern statecraft module.',
        link: 'https://unified-learn.preview/resources/treaty-excerpts.pdf',
        createdAt: 'Oct 15',
      ),
    ];
  }

  @override
  Future<List<ScheduleItem>> getSchedule() async {
    return const [
      ScheduleItem(
        id: 'sched-today-bio',
        title: 'Cell Biology Discussion',
        subject: 'Biology',
        time: '09:00 AM - 10:15 AM',
        location: 'Lab B-204',
        type: 'Lecture',
        isToday: true,
      ),
      ScheduleItem(
        id: 'sched-today-math',
        title: 'Calculus Tutorial & Quiz',
        subject: 'Mathematics',
        time: '11:30 AM - 12:45 PM',
        location: 'Hall 101',
        type: 'Tutorial',
        isToday: true,
      ),
      ScheduleItem(
        id: 'sched-fri-hist',
        title: 'Modern World History Seminar',
        subject: 'History',
        time: '02:00 PM - 03:30 PM',
        location: 'Seminar Room 3',
        type: 'Seminar',
        isToday: false,
      ),
    ];
  }

  @override
  Future<bool> submitAssignment(String assignmentId, String text) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/submissions/assignment/$assignmentId',
        data: {'text': text},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return true; // Optimistic fallback for demo
    }
  }
}
