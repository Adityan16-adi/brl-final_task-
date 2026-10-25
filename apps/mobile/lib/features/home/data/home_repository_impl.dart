import '../domain/home_repository.dart';

class InMemoryHomeRepository implements HomeRepository {
  InMemoryHomeRepository() {
    _initData();
  }

  final List<ClassroomItem> _classrooms = [];
  final List<AssignmentItem> _assignments = [];
  final List<MaterialItem> _materials = [];
  final List<ScheduleItem> _schedules = [];

  void _initData() {
    _classrooms.addAll([
      const ClassroomItem(
        id: 'class-cell-biology',
        name: 'Cell Biology & Genetics',
        subject: 'Biology',
        teacher: 'Dr. Jane Smith',
        schedule: 'Mon, Wed 09:00 AM',
        room: 'Lab B-204',
        studentCount: 28,
        code: 'CELL24',
        isEnrolled: true,
      ),
      const ClassroomItem(
        id: 'class-calc-mechanics',
        name: 'Calculus & Linear Algebra',
        subject: 'Mathematics',
        teacher: 'Prof. David Lee',
        schedule: 'Tue, Thu 11:30 AM',
        room: 'Hall 101',
        studentCount: 34,
        code: 'MATH28',
        isEnrolled: true,
      ),
      const ClassroomItem(
        id: 'class-mod-history',
        name: 'Modern World History',
        subject: 'History',
        teacher: 'Elena Rostova',
        schedule: 'Fri 02:00 PM',
        room: 'Seminar Room 3',
        studentCount: 22,
        code: 'PAST21',
        isEnrolled: true,
      ),
    ]);

    _assignments.addAll([
      const AssignmentItem(
        id: 'assign-cell-notes',
        title: 'Cell Structures Concept Map',
        subject: 'Biology',
        dueDate: 'Tomorrow, 11:59 PM',
        points: 20,
        status: AssignmentStatus.pending,
        description: 'Create a conceptual diagram mapping eukaryotic vs prokaryotic organelle functions.',
      ),
      const AssignmentItem(
        id: 'assign-calc-ps3',
        title: 'Problem Set 3: Derivatives & Rates',
        subject: 'Mathematics',
        dueDate: 'In 3 days',
        points: 30,
        status: AssignmentStatus.pending,
        description: 'Complete questions 1 to 15 from Chapter 4 on implicit differentiation.',
      ),
      const AssignmentItem(
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
    ]);

    _materials.addAll([
      const MaterialItem(
        id: 'mat-cell-slides',
        title: 'Eukaryotic Cell Architecture Slide Deck',
        subject: 'Biology',
        type: CourseMaterialType.notes,
        details: 'Lecture 4 summary slides covering membrane transport and organelles.',
        link: 'https://unified-learn.preview/resources/cell-architecture.pdf',
        createdAt: 'Oct 20',
      ),
      const MaterialItem(
        id: 'mat-calc-video',
        title: 'Chain Rule & Quotient Rule Walkthrough',
        subject: 'Mathematics',
        type: CourseMaterialType.video,
        details: 'Recorded problem solving session with step-by-step calculus proofs.',
        link: 'https://unified-learn.preview/resources/chain-rule-video',
        createdAt: 'Oct 18',
      ),
      const MaterialItem(
        id: 'mat-history-treaty',
        title: 'Treaty Excerpts & Historical Archive Documents',
        subject: 'History',
        type: CourseMaterialType.document,
        details:
            'Annotated diplomatic correspondence and primary document scans.',
        link: 'https://unified-learn.preview/resources/treaty-excerpts.pdf',
        createdAt: 'Oct 15',
      ),
    ]);

    _schedules.addAll([
      const ScheduleItem(
        id: 'sched-1',
        title: 'Cell Biology Live Lab',
        subject: 'Biology',
        time: 'Today · 09:00 AM - 10:30 AM',
        location: 'Lab B-204 · Live Meeting Link',
        type: 'Lab Session',
        isToday: true,
      ),
      const ScheduleItem(
        id: 'sched-2',
        title: 'Calculus Problem Clinic',
        subject: 'Mathematics',
        time: 'Today · 02:00 PM - 03:30 PM',
        location: 'Hall 101 · Virtual Session',
        type: 'Lecture',
        isToday: true,
      ),
      const ScheduleItem(
        id: 'sched-3',
        title: 'History Discussion Round',
        subject: 'History',
        time: 'Tomorrow · 10:00 AM - 11:30 AM',
        location: 'Seminar Room 3',
        type: 'Seminar',
        isToday: false,
      ),
    ]);
  }

  @override
  Future<HomeSummary> getSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final pendingCount = _assignments
        .where((a) => a.status == AssignmentStatus.pending)
        .length;
    final nextClass = _schedules.isNotEmpty ? _schedules.first : null;

    return HomeSummary(
      enrolledClassesCount: _classrooms.length,
      pendingAssignmentsCount: pendingCount,
      materialsCount: _materials.length,
      nextClassTitle: nextClass?.title,
      nextClassTime: nextClass?.time,
    );
  }

  @override
  Future<List<ClassroomItem>> getClassrooms() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return List.unmodifiable(_classrooms);
  }

  @override
  Future<List<AssignmentItem>> getAssignments() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return List.unmodifiable(_assignments);
  }

  @override
  Future<List<MaterialItem>> getMaterials() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return List.unmodifiable(_materials);
  }

  @override
  Future<List<ScheduleItem>> getSchedule() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return List.unmodifiable(_schedules);
  }

  @override
  Future<ClassroomItem> createClassroom({
    required String name,
    required String subject,
    String? description,
    String? schedule,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (name.trim().isEmpty) {
      throw const ClassroomException(
        'Classroom name is required',
        statusCode: 400,
      );
    }
    if (subject.trim().isEmpty) {
      throw const ClassroomException('Subject is required', statusCode: 400);
    }

    final code = DateTime.now().millisecondsSinceEpoch
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, '0')
        .substring(0, 8);

    final item = ClassroomItem(
      id: 'class-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      subject: subject.trim(),
      teacher: 'Demo Teacher',
      schedule: schedule?.trim().isNotEmpty == true
          ? schedule!.trim()
          : 'Flexible Online',
      room: 'Lab 101',
      studentCount: 0,
      code: code,
      description: description?.trim() ?? '',
      isEnrolled: true,
    );

    _classrooms.insert(0, item);
    return item;
  }

  @override
  Future<ClassroomItem> joinClassroom(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw const ClassroomException(
        'Classroom code is required',
        statusCode: 400,
      );
    }

    // Check for duplicate enrollment
    final alreadyEnrolled = _classrooms.any((c) => c.code == normalized);
    if (alreadyEnrolled) {
      throw const ClassroomException(
        'Already joined this classroom',
        statusCode: 409,
      );
    }

    // Sample preview codes
    if (normalized == 'PHYS40') {
      const item = ClassroomItem(
        id: 'class-physics-mechanics',
        name: 'Applied Classical Mechanics',
        subject: 'Physics',
        teacher: 'Dr. Jane Smith',
        schedule: 'Thu 03:00 PM',
        room: 'Physics Lab 2',
        studentCount: 19,
        code: 'PHYS40',
        isEnrolled: true,
      );
      _classrooms.insert(0, item);
      return item;
    }

    if (normalized == 'CHEM10') {
      const item = ClassroomItem(
        id: 'class-chem-101',
        name: 'General Chemistry Principles',
        subject: 'Chemistry',
        teacher: 'Dr. Marcus Vance',
        schedule: 'Tue 09:30 AM',
        room: 'Chemistry Hall C',
        studentCount: 25,
        code: 'CHEM10',
        isEnrolled: true,
      );
      _classrooms.insert(0, item);
      return item;
    }

    if (RegExp(r'^[A-Z0-9]{4,10}$').hasMatch(normalized)) {
      final item = ClassroomItem(
        id: 'class-${DateTime.now().millisecondsSinceEpoch}',
        name: '$normalized Classroom',
        subject: 'General Study',
        teacher: 'Course Instructor',
        schedule: 'Flexible Online',
        room: 'Virtual Room',
        studentCount: 12,
        code: normalized,
        isEnrolled: true,
      );
      _classrooms.insert(0, item);
      return item;
    }

    throw const ClassroomException('Invalid classroom code', statusCode: 404);
  }

  @override
  Future<ClassroomDetails> getClassroomDetails(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final item = _classrooms.firstWhere(
      (c) => c.id == id,
      orElse: () => ClassroomItem(
        id: id,
        name: 'Active Classroom',
        subject: 'General Study',
        teacher: 'Course Instructor',
        schedule: 'Flexible Online',
        room: 'Virtual Room',
        studentCount: 1,
        code: 'CLASS01',
      ),
    );

    return ClassroomDetails(
      id: item.id,
      name: item.name,
      subject: item.subject,
      teacher: item.teacher,
      teacherUid: 'teacher-uid',
      code: item.code ?? 'CLASS01',
      schedule: item.schedule,
      description: item.description,
      studentCount: item.studentCount,
      students: const [
        EnrolledStudent(
          uid: 'mock-student-01',
          name: 'Demo Student',
          email: 'student@demo.com',
        ),
      ],
      isTeacher: true,
    );
  }

  @override
  Future<bool> submitAssignment(
    String assignmentId,
    String text, {
    String? studentId,
    String? fileUrl,
    String? fileName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final index = _assignments.indexWhere((a) => a.id == assignmentId);
    if (index == -1) return false;

    _assignments[index] = _assignments[index].copyWith(
      status: AssignmentStatus.submitted,
      submittedText: text,
      submittedFileUrl: fileUrl,
      submittedAt: DateTime.now(),
    );
    return true;
  }

  @override
  Future<AssignmentItem> createAssignment({
    required String classId,
    required String title,
    required String subject,
    required String dueDate,
    required int points,
    String? description,
    String? createdBy,
    String? attachmentUrl,
    String? attachmentName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final item = AssignmentItem(
      id: 'assign-${DateTime.now().millisecondsSinceEpoch}',
      classId: classId,
      title: title.trim(),
      subject: subject.trim(),
      dueDate: dueDate.trim(),
      points: points,
      status: AssignmentStatus.pending,
      description: description?.trim() ?? '',
      attachmentUrl: attachmentUrl?.trim(),
      attachmentName: attachmentName?.trim(),
    );
    _assignments.insert(0, item);
    return item;
  }

  @override
  Future<bool> gradeSubmission(
    String submissionId, {
    required int marks,
    String? feedback,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _assignments.indexWhere((a) => a.id == submissionId);
    if (index != -1) {
      _assignments[index] = _assignments[index].copyWith(
        status: AssignmentStatus.graded,
        marks: marks,
        feedback: feedback,
      );
    }
    return true;
  }


  final Map<String, List<AttendanceSession>> _attendanceSessions = {};

  @override
  Future<List<AttendanceSession>> getClassAttendance(String classId) async {
    return _attendanceSessions[classId] ?? const [];
  }

  @override
  Future<bool> takeAttendance({
    required String classId,
    required DateTime sessionDate,
    required List<AttendanceRecordItem> records,
    String? topic,
  }) async {
    final session = AttendanceSession(
      id: 'mock-att-${DateTime.now().millisecondsSinceEpoch}',
      classId: classId,
      sessionDate: sessionDate,
      topic: topic ?? 'Regular Session',
      records: records,
    );
    _attendanceSessions.putIfAbsent(classId, () => []).insert(0, session);
    return true;
  }

  @override
  Future<StudentAttendanceSummary> getStudentAttendance(String studentUid) async {
    int total = 0;
    int present = 0;
    int absent = 0;
    int late = 0;
    final sessionsList = <Map<String, dynamic>>[];

    for (final sessions in _attendanceSessions.values) {
      for (final s in sessions) {
        final rec = s.records.where((r) => r.studentUid == studentUid).firstOrNull;
        if (rec != null) {
          total++;
          if (rec.status == 'present') {
            present++;
          } else if (rec.status == 'late') {
            late++;
          } else {
            absent++;
          }
          sessionsList.add({
            'attendanceId': s.id,
            'classId': s.classId,
            'className': 'Classroom',
            'sessionDate': s.sessionDate.toIso8601String(),
            'topic': s.topic,
            'status': rec.status,
            'remarks': rec.remarks,
          });
        }
      }
    }

    if (total == 0) {
      return StudentAttendanceSummary(
        totalSessions: 10,
        presentCount: 9,
        absentCount: 0,
        lateCount: 1,
        percentage: 95,
        sessions: [
          {
            'attendanceId': 'att-mock-1',
            'className': 'Cell Biology',
            'sessionDate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'topic': 'Membrane Transport & Osmosis',
            'status': 'present',
            'remarks': 'Active participation',
          },
        ],
      );
    }

    final pct = total > 0 ? (((present + (late * 0.5)) / total) * 100).round() : 100;
    return StudentAttendanceSummary(
      totalSessions: total,
      presentCount: present,
      absentCount: absent,
      lateCount: late,
      percentage: pct,
      sessions: sessionsList,
    );
  }
}