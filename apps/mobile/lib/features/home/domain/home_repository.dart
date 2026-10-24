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
  Future<List<ScheduleItem>> getSchedule();
  Future<bool> submitAssignment(String assignmentId, String text);
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

class AssignmentItem {
  const AssignmentItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.points,
    required this.status,
    this.description = '',
    this.submittedText,
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
  final String? submittedText;
  final int? marks;
  final String? feedback;

  AssignmentItem copyWith({
    AssignmentStatus? status,
    String? submittedText,
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
      submittedText: submittedText ?? this.submittedText,
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
    this.createdAt,
  });

  final String id;
  final String title;
  final String subject;
  final CourseMaterialType type;
  final String details;
  final String? link;
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
  });

  final String id;
  final String title;
  final String subject;
  final String time;
  final String location;
  final String type; // Lecture, Lab, Deadline
  final bool isToday;
}
