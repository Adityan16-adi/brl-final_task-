abstract interface class HomeRepository {
  Future<HomeSummary> getSummary();
  Future<List<ClassroomItem>> getClassrooms();
  Future<ClassroomItem> createClassroom({
    required String name,
    required String subject,
    String? description,
    String? schedule,
  });
  Future<ClassroomItem> joinClassroom(String code);
  Future<ClassroomDetails> getClassroomDetails(String id);
  Future<List<AssignmentItem>> getAssignments();
  Future<List<MaterialItem>> getMaterials();
  Future<MaterialItem> uploadMaterial({
    required String classId,
    required String title,
    required String subject,
    required CourseMaterialType type,
    required String details,
    String? link,
    String? thumbnailUrl,
    String? uploadedBy,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
    void Function(int sent, int total)? onProgress,
  });
  Future<List<ScheduleItem>> getSchedule();
  Future<bool> submitAssignment(
    String assignmentId,
    String text, {
    String? studentId,
    String? link,
    String? fileUrl,
    String? fileName,
    String? filePath,
    List<int>? fileBytes,
    List<SelectedAttachmentItem>? localFiles,
    void Function(int sent, int total)? onProgress,
  });
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
    SelectedAttachmentItem? file,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
    void Function(int sent, int total)? onProgress,
  });
  Future<bool> gradeSubmission(
    String submissionId, {
    required int marks,
    String? feedback,
  });
  Future<List<AttendanceSession>> getClassAttendance(String classId);
  Future<bool> takeAttendance({
    required String classId,
    required DateTime sessionDate,
    required List<AttendanceRecordItem> records,
    String? topic,
  });
  Future<StudentAttendanceSummary> getStudentAttendance(String studentUid);
  Future<List<ChatMessageItem>> getClassMessages(String classId);
  Future<ChatMessageItem> sendChatMessage({
    required String classId,
    required String text,
    String? senderUid,
    String? senderName,
    String? senderRole,
  });
  Future<SpamCheckResult> checkSpam({
    required String meetingId,
    required String userId,
    required String message,
  });
}

class ClassroomException implements Exception {
  const ClassroomException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class HomeSummary {
  const HomeSummary({
    required this.enrolledClassesCount,
    required this.pendingAssignmentsCount,
    required this.materialsCount,
    this.nextClassTitle,
    this.nextClassTime,
  });

  final int enrolledClassesCount;
  final int pendingAssignmentsCount;
  final int materialsCount;
  final String? nextClassTitle;
  final String? nextClassTime;
}

class ClassroomItem {
  const ClassroomItem({
    required this.id,
    required this.name,
    required this.subject,
    required this.teacher,
    required this.schedule,
    required this.room,
    required this.studentCount,
    this.code,
    this.description = '',
    this.isEnrolled = true,
  });

  final String id;
  final String name;
  final String subject;
  final String teacher;
  final String schedule;
  final String room;
  final int studentCount;
  final String? code;
  final String description;
  final bool isEnrolled;

  factory ClassroomItem.fromJson(Map<String, dynamic> json) {
    final studentsList = json['students'] as List<dynamic>? ?? [];
    return ClassroomItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Classroom',
      subject: json['subject']?.toString() ?? 'General',
      teacher:
          json['teacherName']?.toString() ??
          json['teacher']?.toString() ??
          'Course Instructor',
      schedule: json['schedule']?.toString() ?? 'Flexible Online',
      room: json['room']?.toString() ?? 'Virtual Room',
      studentCount: json['studentCount'] as int? ?? studentsList.length,
      code: json['code']?.toString(),
      description: json['description']?.toString() ?? '',
      isEnrolled: true,
    );
  }
}

class EnrolledStudent {
  const EnrolledStudent({
    required this.uid,
    required this.name,
    required this.email,
  });

  final String uid;
  final String name;
  final String email;

  String get id => uid;

  factory EnrolledStudent.fromJson(Map<String, dynamic> json) {
    return EnrolledStudent(
      uid: json['uid']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Student',
      email: json['email']?.toString() ?? '',
    );
  }
}

class ClassroomDetails {
  const ClassroomDetails({
    required this.id,
    required this.name,
    required this.subject,
    required this.teacher,
    required this.teacherUid,
    required this.code,
    required this.schedule,
    required this.description,
    required this.studentCount,
    required this.students,
    required this.isTeacher,
  });

  final String id;
  final String name;
  final String subject;
  final String teacher;
  final String teacherUid;
  final String code;
  final String schedule;
  final String description;
  final int studentCount;
  final List<EnrolledStudent> students;
  final bool isTeacher;

  factory ClassroomDetails.fromJson(Map<String, dynamic> json) {
    final studentProfiles = json['studentProfiles'] as List<dynamic>? ?? [];
    final studentsList = json['students'] as List<dynamic>? ?? [];
    return ClassroomDetails(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      subject: json['subject']?.toString() ?? 'General',
      teacher:
          json['teacherName']?.toString() ??
          json['teacher']?.toString() ??
          'Course Instructor',
      teacherUid: json['teacherUid']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      schedule: json['schedule']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      studentCount:
          json['studentCount'] as int? ??
          (studentProfiles.isNotEmpty
              ? studentProfiles.length
              : studentsList.length),
      students: studentProfiles
          .map((s) => EnrolledStudent.fromJson(s as Map<String, dynamic>))
          .toList(),
      isTeacher: json['isTeacher'] == true,
    );
  }
}

enum AssignmentStatus { pending, submitted, graded }

class SubmissionAttachment {
  const SubmissionAttachment({
    required this.url,
    this.name = '',
    this.publicId = '',
    this.resourceType = 'raw',
    this.fileType = '',
    this.size = 0,
  });

  final String url;
  final String name;
  final String publicId;
  final String resourceType;
  final String fileType;
  final int size;

  Map<String, dynamic> toJson() => {
        'url': url,
        'name': name,
        'publicId': publicId,
        'resourceType': resourceType,
        'fileType': fileType,
        'size': size,
      };

  factory SubmissionAttachment.fromJson(Map<String, dynamic> json) =>
      SubmissionAttachment(
        url: json['url']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        publicId: json['publicId']?.toString() ?? '',
        resourceType: json['resourceType']?.toString() ?? 'raw',
        fileType: json['fileType']?.toString() ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
      );
}

class SelectedAttachmentItem {
  const SelectedAttachmentItem({
    required this.name,
    this.path,
    this.bytes,
    this.size = 0,
    this.mimeType,
  });

  final String name;
  final String? path;
  final List<int>? bytes;
  final int size;
  final String? mimeType;
}

class AssignmentItem {
  const AssignmentItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.points,
    required this.status,
    this.description = '',
    this.classId,
    this.attachmentUrl,
    this.attachmentName,
    this.submittedText,
    this.submittedLink,
    this.submittedFileUrl,
    this.attachments = const [],
    this.submittedAt,
    this.isLate = false,
    this.marks,
    this.feedback,
  });

  final String id;
  final String title;
  final String subject;
  final String dueDate;
  final int points;
  final AssignmentStatus status;
  final String description;
  final String? classId;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? submittedText;
  final String? submittedLink;
  final String? submittedFileUrl;
  final List<SubmissionAttachment> attachments;
  final DateTime? submittedAt;
  final bool isLate;
  final int? marks;
  final String? feedback;

  bool get isDueIn24h {
    if (status == AssignmentStatus.submitted ||
        status == AssignmentStatus.graded) {
      return false;
    }
    try {
      final parsed = DateTime.tryParse(dueDate);
      if (parsed != null) {
        final diff = parsed.difference(DateTime.now());
        return diff.inHours >= 0 && diff.inHours <= 24;
      }
    } catch (_) {}
    return dueDate.toLowerCase().contains('today') ||
        dueDate.toLowerCase().contains('in 24h');
  }

  bool get isDueSoon {
    if (status == AssignmentStatus.submitted ||
        status == AssignmentStatus.graded) {
      return false;
    }
    if (isDueIn24h) return true;
    try {
      final parsed = DateTime.tryParse(dueDate);
      if (parsed != null) {
        final diff = parsed.difference(DateTime.now());
        return diff.inHours >= 0 && diff.inHours <= 48;
      }
    } catch (_) {}
    final lower = dueDate.toLowerCase();
    return lower.contains('tomorrow') ||
        lower.contains('soon') ||
        lower.contains('due tomorrow');
  }

  AssignmentItem copyWith({
    AssignmentStatus? status,
    String? classId,
    String? attachmentUrl,
    String? attachmentName,
    String? submittedText,
    String? submittedLink,
    String? submittedFileUrl,
    List<SubmissionAttachment>? attachments,
    DateTime? submittedAt,
    bool? isLate,
    int? marks,
    String? feedback,
  }) {
    return AssignmentItem(
      id: id,
      title: title,
      subject: subject,
      dueDate: dueDate,
      points: points,
      status: status ?? this.status,
      description: description,
      classId: classId ?? this.classId,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      submittedText: submittedText ?? this.submittedText,
      submittedLink: submittedLink ?? this.submittedLink,
      submittedFileUrl: submittedFileUrl ?? this.submittedFileUrl,
      attachments: attachments ?? this.attachments,
      submittedAt: submittedAt ?? this.submittedAt,
      isLate: isLate ?? this.isLate,
      marks: marks ?? this.marks,
      feedback: feedback ?? this.feedback,
    );
  }
}

enum CourseMaterialType { notes, video, document }

class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.details,
    this.link,
    this.thumbnailUrl,
    this.createdAt,
  });

  final String id;
  final String title;
  final String subject;
  final CourseMaterialType type;
  final String details;
  final String? link;
  final String? thumbnailUrl;
  final String? createdAt;
}

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.time,
    required this.location,
    required this.type,
    this.isToday = false,
    this.date,
  });

  final String id;
  final String title;
  final String subject;
  final String time;
  final String location;
  final String type; // Lecture, Lab, Deadline
  final bool isToday;
  final DateTime? date;
}


class AttendanceRecordItem {
  const AttendanceRecordItem({
    required this.studentUid,
    required this.studentName,
    required this.status,
    this.remarks = '',
  });

  final String studentUid;
  final String studentName;
  final String status; // present, absent, late, excused
  final String remarks;

  Map<String, dynamic> toJson() => {
        'studentUid': studentUid,
        'studentName': studentName,
        'status': status,
        'remarks': remarks,
      };

  factory AttendanceRecordItem.fromJson(Map<String, dynamic> json) =>
      AttendanceRecordItem(
        studentUid: json['studentUid']?.toString() ??
            json['uid']?.toString() ??
            '',
        studentName: json['studentName']?.toString() ??
            json['name']?.toString() ??
            'Student',
        status: json['status']?.toString() ?? 'present',
        remarks: json['remarks']?.toString() ?? '',
      );
}

class AttendanceSession {
  const AttendanceSession({
    required this.id,
    required this.classId,
    required this.sessionDate,
    required this.topic,
    required this.records,
  });

  final String id;
  final String classId;
  final DateTime sessionDate;
  final String topic;
  final List<AttendanceRecordItem> records;

  int get presentCount =>
      records.where((r) => r.status.toLowerCase() == 'present').length;
  int get lateCount =>
      records.where((r) => r.status.toLowerCase() == 'late').length;
  int get absentCount =>
      records.where((r) => r.status.toLowerCase() == 'absent').length;

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    final recordsRaw = json['records'] as List<dynamic>? ?? [];
    return AttendanceSession(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      classId: json['classId'] is Map
          ? (json['classId']['_id']?.toString() ?? '')
          : (json['classId']?.toString() ?? ''),
      sessionDate: json['sessionDate'] != null
          ? DateTime.tryParse(json['sessionDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      topic: json['topic']?.toString() ?? 'Regular Session',
      records: recordsRaw
          .map((r) => AttendanceRecordItem.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentAttendanceSummary {
  const StudentAttendanceSummary({
    required this.totalSessions,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.percentage,
    this.sessions = const [],
  });

  final int totalSessions;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int percentage;
  final List<Map<String, dynamic>> sessions;

  factory StudentAttendanceSummary.fromJson(Map<String, dynamic> json) {
    final list = json['sessions'] as List<dynamic>? ?? [];
    return StudentAttendanceSummary(
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 100,
      sessions: list.map((s) => s as Map<String, dynamic>).toList(),
    );
  }
}

class ChatMessageItem {
  const ChatMessageItem({
    required this.id,
    required this.classId,
    required this.senderUid,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    this.isSpam = false,
  });

  final String id;
  final String classId;
  final String senderUid;
  final String senderName;
  final String senderRole; // 'teacher' | 'student'
  final String text;
  final DateTime createdAt;
  final bool isSpam;

  bool get isTeacher => senderRole.toLowerCase() == 'teacher';

  Map<String, dynamic> toJson() => {
        'id': id,
        'classId': classId,
        'senderUid': senderUid,
        'senderName': senderName,
        'senderRole': senderRole,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'isSpam': isSpam,
      };

  factory ChatMessageItem.fromJson(Map<String, dynamic> json) =>
      ChatMessageItem(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        classId: json['classId']?.toString() ?? '',
        senderUid: json['senderUid']?.toString() ?? '',
        senderName: json['senderName']?.toString() ?? 'User',
        senderRole: json['senderRole']?.toString() ?? 'student',
        text: json['text']?.toString() ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isSpam: json['isSpam'] == true,
      );
}

class SpamCheckResult {
  const SpamCheckResult({
    required this.isSpam,
    required this.score,
    required this.action,
    this.reasons = const [],
  });

  final bool isSpam;
  final int score;
  final String action; // 'allow', 'warn', 'block', 'blocked'
  final List<String> reasons;

  factory SpamCheckResult.fromJson(Map<String, dynamic> json) =>
      SpamCheckResult(
        isSpam: json['is_spam'] == true,
        score: (json['score'] as num?)?.toInt() ?? 0,
        action: json['action']?.toString() ?? 'allow',
        reasons: (json['reasons'] as List<dynamic>?)
                ?.map((r) => r.toString())
                .toList() ??
            const [],
      );
}
