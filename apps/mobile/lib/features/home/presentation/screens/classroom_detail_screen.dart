import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/errors/error_message_helper.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/clay_theme.dart';
import '../../../auth/application/auth_providers.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';
import '../widgets/create_assignment_dialog.dart';
import '../widgets/submit_assignment_dialog.dart';
import 'live_meeting_screen.dart';

class ClassroomAnnouncement {
  const ClassroomAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    this.isPinned = false,
  });

  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;
  final bool isPinned;
}

class ClassroomDetailScreen extends ConsumerStatefulWidget {
  const ClassroomDetailScreen({required this.classroom, super.key});

  final ClassroomItem classroom;

  @override
  ConsumerState<ClassroomDetailScreen> createState() =>
      _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends ConsumerState<ClassroomDetailScreen> {
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _isSessionActive = false;
  bool _handRaised = false;
  int _activeTabIndex = 0; // 0: Meeting Room, 1: Coursework, 2: Attendance, 3: Chat, 4: Learners

  late List<ClassroomAnnouncement> _announcements;

  DateTime _attendanceDate = DateTime.now();
  final TextEditingController _attendanceTopicCtrl =
      TextEditingController(text: 'Regular Session');
  final Map<String, String> _attendanceStatuses = {};
  final Map<String, TextEditingController> _attendanceRemarks = {};
  bool _isSavingAttendance = false;
  int _attendanceRefreshKey = 0;

  final TextEditingController _chatCtrl = TextEditingController();
  bool _isSendingChat = false;
  int _chatRefreshKey = 0;

  @override
  void dispose() {
    _attendanceTopicCtrl.dispose();
    for (final ctrl in _attendanceRemarks.values) {
      ctrl.dispose();
    }
    _chatCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _announcements = [
      ClassroomAnnouncement(
        id: 'ann-1',
        title: 'Welcome to ${widget.classroom.name}!',
        content:
            'Please review the attached materials, verify submission deadlines, and reach out in class chat for any questions.',
        author: widget.classroom.teacher.isNotEmpty
            ? widget.classroom.teacher
            : 'Course Instructor',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isPinned: true,
      ),
      ClassroomAnnouncement(
        id: 'ann-2',
        title: 'Live Interactive Session',
        content:
            'Join the meeting lobby with your microphone and camera configured. Live video calling is supported.',
        author: widget.classroom.teacher.isNotEmpty
            ? widget.classroom.teacher
            : 'Course Instructor',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
    // If the classroom was started now, mark session active
    final sched = widget.classroom.schedule.toLowerCase();
    if (sched.contains('now') ||
        sched.contains('live') ||
        sched.contains('started')) {
      _isSessionActive = true;
    }
  }

  void _copyClassCode(BuildContext context) {
    if (widget.classroom.code == null) return;
    Clipboard.setData(ClipboardData(text: widget.classroom.code!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Class code "${widget.classroom.code}" copied to clipboard!',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String? _customMeetingUrl;

  String get _meetingUrl {
    if (_customMeetingUrl != null && _customMeetingUrl!.trim().isNotEmpty) {
      return _customMeetingUrl!.trim();
    }
    final rawCode = widget.classroom.code?.trim().isNotEmpty == true
        ? widget.classroom.code!.trim()
        : widget.classroom.id.trim();
    final sanitized = rawCode.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
    return 'https://meet.jit.si/Pragti-${sanitized.isNotEmpty ? sanitized : "Class"}';
  }

  void _copyMeetingLink(BuildContext context, {bool launch = false}) {
    final link = _meetingUrl;
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          launch
              ? 'Meeting link copied to clipboard! Open in any browser:\n$link'
              : 'Meeting link copied to clipboard: $link',
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _showSetCustomLinkDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: _customMeetingUrl ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Meeting Link'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a custom Google Meet, Zoom, or Jitsi room URL for this class:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'Meeting URL',
                  hintText: 'https://meet.google.com/xyz-abcd-efg',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    if (!val.trim().startsWith('http://') &&
                        !val.trim().startsWith('https://')) {
                      return 'URL must start with http:// or https://';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          if (_customMeetingUrl != null && _customMeetingUrl!.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() => _customMeetingUrl = null);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset to default Jitsi room.')),
                );
              },
              child: const Text('Reset Default'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayTokens.deepIndigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final url = ctrl.text.trim();
                setState(() {
                  _customMeetingUrl = url.isEmpty ? null : url;
                });
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      url.isEmpty
                          ? 'Reset to default Jitsi room.'
                          : 'Custom meeting link saved!',
                    ),
                    backgroundColor: ClayTokens.mintDark,
                  ),
                );
              }
            },
            child: const Text('Save Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchResourceUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment link copied to clipboard.')),
      );
    }
  }

  Future<void> _showGradingDialog(
    BuildContext context,
    AssignmentItem assignment,
  ) async {
    final marksCtrl = TextEditingController(
      text: assignment.marks?.toString() ?? '',
    );
    final feedbackCtrl = TextEditingController(
      text: assignment.feedback ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final submittedAtStr = assignment.submittedAt != null
        ? '${assignment.submittedAt!.year}-${assignment.submittedAt!.month.toString().padLeft(2, '0')}-${assignment.submittedAt!.day.toString().padLeft(2, '0')} ${assignment.submittedAt!.hour.toString().padLeft(2, '0')}:${assignment.submittedAt!.minute.toString().padLeft(2, '0')}'
        : null;

    final submissionLink = assignment.submittedLink ??
        (assignment.submittedFileUrl != null &&
                assignment.submittedFileUrl!.startsWith('http')
            ? assignment.submittedFileUrl
            : null);

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Grade: ${assignment.title}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Maximum Points: ${assignment.points}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ClayTokens.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (submittedAtStr != null)
                        Text(
                          '• Submitted: $submittedAtStr',
                          style: const TextStyle(
                            fontSize: 11,
                            color: ClayTokens.secondaryText,
                          ),
                        ),
                      if (assignment.isLate)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'LATE SUBMISSION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Student's written solution
                  if (assignment.submittedText != null &&
                      assignment.submittedText!.isNotEmpty) ...[
                    const Text(
                      'Student Solution / Notes:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ClayTokens.lightSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        assignment.submittedText!,
                        style: const TextStyle(fontSize: 13, height: 1.3),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Student's submission link
                  if (submissionLink != null && submissionLink.isNotEmpty) ...[
                    const Text(
                      'Submission Link:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _launchResourceUrl(submissionLink),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link_rounded, size: 16, color: Colors.blue),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                submissionLink,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.blue),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Attached files
                  if (assignment.attachments.isNotEmpty) ...[
                    const Text(
                      'Attached Student Files:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...assignment.attachments.map((att) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: ClayTokens.mint.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.attachment_rounded, size: 16, color: ClayTokens.mintDark),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  att.name.isNotEmpty ? att.name : att.url,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                tooltip: 'Open attachment',
                                onPressed: () => _launchResourceUrl(att.url),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 12),
                  ] else if (assignment.submittedFileUrl != null &&
                      assignment.submittedFileUrl!.isNotEmpty &&
                      submissionLink != assignment.submittedFileUrl) ...[
                    const Text(
                      'Attached File:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _launchResourceUrl(assignment.submittedFileUrl!),
                      child: Row(
                        children: [
                          const Icon(Icons.file_present_rounded, size: 16, color: Colors.blue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              assignment.submittedFileUrl!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.blue),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const Divider(height: 20),
                  TextFormField(
                    controller: marksCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Awarded Marks (0 - ${assignment.points})',
                      hintText: 'e.g. ${assignment.points}',
                      prefixIcon: const Icon(Icons.score_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter marks';
                      }
                      final parsed = int.tryParse(val.trim());
                      if (parsed == null) return 'Must be a valid integer';
                      if (parsed < 0 || parsed > assignment.points) {
                        return 'Must be between 0 and ${assignment.points}';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: feedbackCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Instructor Feedback Remarks',
                      hintText: 'e.g. Great understanding of concepts and proofs.',
                      prefixIcon: Icon(Icons.rate_review_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ClayTokens.deepIndigo,
                foregroundColor: Colors.white,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);
                      final marks = int.parse(marksCtrl.text.trim());
                      final feedback = feedbackCtrl.text.trim();

                      final success = await ref
                          .read(homeRepositoryProvider)
                          .gradeSubmission(
                            assignment.id,
                            marks: marks,
                            feedback: feedback,
                          );

                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                      if (context.mounted) {
                        ref.invalidate(assignmentsProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Submission graded successfully ($marks/${assignment.points})!'
                                  : 'Grade saved locally.',
                            ),
                            backgroundColor: ClayTokens.mintDark,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Grade'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isTeacher = ref.watch(isTeacherProvider);
    final assignmentsAsync = ref.watch(assignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Classroom Hub',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (widget.classroom.code != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share Join Code',
              onPressed: () => _copyClassCode(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // Header Clay Card
          ClayCard(
            depth: 5,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ClayBadge(
                      label: widget.classroom.subject,
                      backgroundColor: ClayTokens.softLavender,
                      textColor: ClayTokens.deepIndigo,
                    ),
                    if (widget.classroom.code != null)
                      GestureDetector(
                        onTap: () => _copyClassCode(context),
                        child: ClayContainer(
                          depth: 2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'CODE: ${widget.classroom.code}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy_rounded, size: 14),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.classroom.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                if (widget.classroom.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.classroom.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: ClayTokens.softLavender,
                      child: Text(
                        widget.classroom.teacher.isNotEmpty
                            ? widget.classroom.teacher[0].toUpperCase()
                            : 'T',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ClayTokens.deepIndigo,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Instructor: ${widget.classroom.teacher}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.classroom.studentCount} enrolled',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isSessionActive
                        ? Colors.green.withValues(alpha: 0.12)
                        : colors.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isSessionActive
                          ? Colors.green.withValues(alpha: 0.4)
                          : colors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSessionActive
                            ? Icons.fiber_manual_record_rounded
                            : Icons.access_time_rounded,
                        color: _isSessionActive ? Colors.green : colors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isSessionActive
                              ? 'Active Class Session · In Progress'
                              : 'Schedule: ${widget.classroom.schedule.isNotEmpty ? widget.classroom.schedule : "Flexible Online"}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _isSessionActive
                                ? Colors.green.shade800
                                : colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Tab Navigation Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.meeting_room_rounded),
                  label: Text('Meeting Lobby'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.assignment_rounded),
                  label: Text('Coursework'),
                ),
                ButtonSegment(
                  value: 2,
                  icon: Icon(Icons.how_to_reg_rounded),
                  label: Text('Attendance'),
                ),
                ButtonSegment(
                  value: 3,
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  label: Text('Chat'),
                ),
                ButtonSegment(
                  value: 4,
                  icon: Icon(Icons.people_rounded),
                  label: Text('Learners'),
                ),
              ],
              selected: {_activeTabIndex},
              onSelectionChanged: (set) {
                setState(() => _activeTabIndex = set.first);
              },
            ),
          ),
          const SizedBox(height: 18),

          // Tab Content
          if (_activeTabIndex == 0) ...[
            _buildMeetingRoomSection(context, isTeacher),
          ] else if (_activeTabIndex == 1) ...[
            _buildCourseworkSection(context, isTeacher, assignmentsAsync),
          ] else if (_activeTabIndex == 2) ...[
            _buildAttendanceSection(context, isTeacher),
          ] else if (_activeTabIndex == 3) ...[
            _buildChatSection(context, isTeacher),
          ] else ...[
            _buildLearnersSection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildMeetingRoomSection(BuildContext context, bool isTeacher) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClayCard(
          depth: 4,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClayContainer(
                    width: 36,
                    height: 36,
                    depth: 2,
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: Icon(
                        Icons.videocam_rounded,
                        color: _isSessionActive
                            ? Colors.green
                            : ClayTokens.deepIndigo,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSessionActive
                              ? 'Live Class Lobby (Active)'
                              : 'Virtual Meeting Lobby',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _isSessionActive
                              ? 'Room open · Learners can connect now'
                              : 'Session scheduled for this classroom',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Transparent Architecture Disclaimer Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Classroom lobby and participant presence are live. Direct WebRTC / Agora video streaming requires video provider API keys configured on the backend server.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Device Audio & Video Readiness Controls
              Text(
                'Lobby Readiness Test',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _micEnabled
                            ? colors.primaryContainer.withValues(alpha: 0.3)
                            : null,
                      ),
                      onPressed: () {
                        setState(() => _micEnabled = !_micEnabled);
                      },
                      icon: Icon(
                        _micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                        size: 18,
                        color: _micEnabled ? colors.primary : colors.error,
                      ),
                      label: Text(_micEnabled ? 'Mic: Ready' : 'Mic: Muted'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _cameraEnabled
                            ? colors.primaryContainer.withValues(alpha: 0.3)
                            : null,
                      ),
                      onPressed: () {
                        setState(() => _cameraEnabled = !_cameraEnabled);
                      },
                      icon: Icon(
                        _cameraEnabled
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        size: 18,
                        color: _cameraEnabled ? colors.primary : colors.error,
                      ),
                      label: Text(_cameraEnabled ? 'Cam: Ready' : 'Cam: Off'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Role-Specific Action Controls
              if (isTeacher) ...[
                ClayButton(
                  isFullWidth: true,
                  icon: _isSessionActive
                      ? Icons.videocam_rounded
                      : Icons.play_circle_fill_rounded,
                  onPressed: () {
                    setState(() => _isSessionActive = true);
                    _joinLiveVideoCall(context, true);
                  },
                  child: Text(
                    _isSessionActive
                        ? 'Join Live Video Session'
                        : 'Start Live Video Session',
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          _joinLiveVideoCall(context, false);
                        },
                        icon: const Icon(Icons.videocam_rounded, size: 18),
                        label: Text(
                          _isSessionActive ? 'Enter Live Video' : 'Join Video Lobby',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: _handRaised ? 'Lower Hand' : 'Raise Hand',
                      onPressed: () {
                        setState(() => _handRaised = !_handRaised);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _handRaised
                                  ? 'Hand raised! Instructor notified.'
                                  : 'Hand lowered.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.front_hand_rounded,
                        color: _handRaised ? Colors.amber.shade800 : null,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Web Meeting Link (Jitsi / Google Meet Fallback)
        ClayCard(
          depth: 4,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        ClayContainer(
                          width: 36,
                          height: 36,
                          depth: 2,
                          borderRadius: BorderRadius.circular(10),
                          child: const Center(
                            child: Icon(
                              Icons.link_rounded,
                              color: ClayTokens.deepIndigo,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Web Meeting Link',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Jitsi / Google Meet Fallback',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ClayTokens.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const ClayBadge(
                    label: 'ZERO-CONFIG',
                    backgroundColor: ClayTokens.mint,
                    textColor: ClayTokens.mintDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Direct browser-ready video conference. Instant one-click join with no server credentials required.',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              // Meeting URL box
              GestureDetector(
                onTap: () => _copyMeetingLink(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.video_camera_front_rounded, size: 16, color: colors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _meetingUrl,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.copy_rounded, size: 14, color: colors.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (isTeacher) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _copyMeetingLink(context, launch: true),
                      icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                      label: const Text('Launch Zero-Config Meeting'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _copyMeetingLink(context),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Meeting Link'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showSetCustomLinkDialog(context),
                      icon: const Icon(Icons.add_link_rounded, size: 16),
                      label: const Text('Set Custom Meet / Zoom Link'),
                    ),
                  ],
                ),
              ] else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _copyMeetingLink(context, launch: true),
                      icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                      label: const Text('Join via Web / Meet Link'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _copyMeetingLink(context),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Link'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Classroom Announcements Feed
        _buildAnnouncementsSection(context, isTeacher),
      ],
    );
  }

  void _showPostAnnouncementDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, color: ClayTokens.deepIndigo),
            SizedBox(width: 8),
            Text('Post Class Announcement', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Announcement Title',
                  hintText: 'e.g. Exam Schedule Update',
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Announcement Content',
                  hintText: 'Type your message to the class...',
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Message content is required'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style:
                FilledButton.styleFrom(backgroundColor: ClayTokens.deepIndigo),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Publish'),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final user = ref.read(currentUserProvider);
              final newAnn = ClassroomAnnouncement(
                id: 'ann-${DateTime.now().millisecondsSinceEpoch}',
                title: titleCtrl.text.trim(),
                content: contentCtrl.text.trim(),
                author: user?.name ??
                    (widget.classroom.teacher.isNotEmpty
                        ? widget.classroom.teacher
                        : 'Teacher'),
                createdAt: DateTime.now(),
              );
              setState(() => _announcements.insert(0, newAnn));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Announcement published to classroom!'),
                  backgroundColor: ClayTokens.mintDark,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection(BuildContext context, bool isTeacher) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded,
                      color: ClayTokens.deepIndigo, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Class Bulletin (${_announcements.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isTeacher) ...[
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => _showPostAnnouncementDialog(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Notice', style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (_announcements.isEmpty)
          const ClayCard(
            depth: 2,
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No announcements posted for this classroom yet.',
                style: TextStyle(color: ClayTokens.secondaryText),
              ),
            ),
          )
        else
          ..._announcements.map((ann) => _buildAnnouncementCard(context, ann)),
      ],
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    ClassroomAnnouncement ann,
  ) {
    return ClayCard(
      depth: 4,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClayBadge(
                label: ann.author,
                icon: Icons.person_rounded,
                backgroundColor: ClayTokens.softLavender,
                textColor: ClayTokens.deepIndigo,
                fontSize: 10,
              ),
              if (ann.isPinned) ...[
                const SizedBox(width: 6),
                const ClayBadge(
                  label: 'PINNED',
                  icon: Icons.push_pin_rounded,
                  backgroundColor: Color(0xFFFEF3C7),
                  textColor: Color(0xFFD97706),
                  fontSize: 10,
                ),
              ],
              const Spacer(),
              Text(
                '${ann.createdAt.hour.toString().padLeft(2, '0')}:${ann.createdAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 11,
                  color: ClayTokens.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ann.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ann.content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseworkSection(
    BuildContext context,
    bool isTeacher,
    AsyncValue<List<AssignmentItem>> assignmentsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Assignments & Tasks',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            if (isTeacher)
              FilledButton.tonalIcon(
                onPressed: () async {
                  final created = await showDialog<AssignmentItem>(
                    context: context,
                    builder: (_) => const CreateAssignmentDialog(),
                  );
                  if (created != null) {
                    ref.invalidate(assignmentsProvider);
                    ref.invalidate(homeSummaryProvider);
                    ref.invalidate(scheduleProvider);
                  }
                },
                icon: const Icon(Icons.add_task_rounded, size: 16),
                label: const Text('Add Assignment'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        assignmentsAsync.when(
          data: (allAssignments) {
            final classAssignments = allAssignments.where((a) {
              return a.classId == widget.classroom.id ||
                  a.subject.toLowerCase() ==
                      widget.classroom.subject.toLowerCase();
            }).toList();

            final listToDisplay = classAssignments.isNotEmpty
                ? classAssignments
                : allAssignments.take(2).toList();

            if (listToDisplay.isEmpty) {
              return ClayCard(
                depth: 2,
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: Text('No assignments posted for this classroom yet.'),
                ),
              );
            }

            return Column(
              children: listToDisplay.map((a) {
                final isSubmitted = a.status == AssignmentStatus.submitted;
                final isGraded = a.status == AssignmentStatus.graded;
                return ClayCard(
                  depth: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              a.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          ClayBadge(
                            label: isGraded
                                ? 'Graded (${a.marks ?? 0}/${a.points})'
                                : (isSubmitted ? 'Submitted' : 'Pending'),
                            backgroundColor: isGraded
                                ? ClayTokens.mint
                                : (isSubmitted
                                      ? Colors.blue.shade100
                                      : ClayTokens.softPeach),
                            textColor: isGraded
                                ? ClayTokens.mintDark
                                : (isSubmitted
                                      ? Colors.blue.shade900
                                      : ClayTokens.peachDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Due: ${a.dueDate} · ${a.points} Points',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (a.attachmentUrl != null &&
                          a.attachmentUrl!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.attachment_rounded, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                a.attachmentName ?? a.attachmentUrl!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (isTeacher) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.grading_rounded, size: 16),
                            label: Text(
                              isGraded
                                  ? 'Update Grade (${a.marks}/${a.points})'
                                  : 'Review & Grade',
                            ),
                            onPressed: () => _showGradingDialog(context, a),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonal(
                            onPressed: () {
                              showDialog<bool>(
                                context: context,
                                builder: (_) =>
                                    SubmitAssignmentDialog(assignment: a),
                              );
                            },
                            child: Text(
                              isGraded
                                  ? 'View Evaluation'
                                  : (isSubmitted
                                        ? 'Review / Resubmit'
                                        : 'Submit Solution'),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: ClaySkeletonList(itemCount: 2),
          ),
          error: (err, _) => Text('Error loading assignments: $err'),
        ),
      ],
    );
  }

  Widget _buildLearnersSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FutureBuilder<ClassroomDetails>(
      future: ref
          .read(homeRepositoryProvider)
          .getClassroomDetails(widget.classroom.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: ClaySkeletonList(itemCount: 3),
          );
        }

        final details = snapshot.data;
        final students = details?.students ?? [];

        if (students.isEmpty) {
          return ClayCard(
            depth: 2,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.people_outline_rounded, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    'No learners enrolled yet.',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share code "${widget.classroom.code ?? ''}" with your learners.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enrolled Learners (${students.length})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ...students.map((s) {
              return ClayCard(
                depth: 2,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: ClayTokens.softLavender,
                      child: Text(
                        s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: ClayTokens.deepIndigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            s.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceSection(BuildContext context, bool isTeacher) {
    final currentUser = ref.watch(currentUserProvider);

    if (isTeacher) {
      return _buildTeacherAttendanceSection(context);
    } else {
      return _buildStudentAttendanceSection(
        context,
        currentUser?.id ?? 'student-mock-1',
      );
    }
  }

  Widget _buildTeacherAttendanceSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final formattedDate =
        '${_attendanceDate.year}-${_attendanceDate.month.toString().padLeft(2, '0')}-${_attendanceDate.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attendance Header Card with Date & Topic
        ClayCard(
          depth: 3,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.how_to_reg_rounded,
                    color: ClayTokens.deepIndigo,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Attendance Register',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Date picker button
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text('Date: $formattedDate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.onSurface,
                        side: BorderSide(color: colors.outlineVariant),
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _attendanceDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _attendanceDate = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _attendanceTopicCtrl,
                decoration: InputDecoration(
                  labelText: 'Session Topic / Remarks',
                  hintText: 'e.g. Chapter 3: Thermodynamics',
                  isDense: true,
                  prefixIcon: const Icon(Icons.topic_outlined, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Enrolled Students list for marking
        FutureBuilder<ClassroomDetails>(
          future: ref
              .read(homeRepositoryProvider)
              .getClassroomDetails(widget.classroom.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final students = snapshot.data?.students ?? [];
            if (students.isEmpty) {
              return ClayCard(
                depth: 2,
                padding: const EdgeInsets.all(18),
                child: Center(
                  child: Text(
                    'No enrolled students found to mark attendance.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              );
            }

            // Initialize default 'present' for any new students
            for (final s in students) {
              _attendanceStatuses.putIfAbsent(s.id, () => 'present');
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Roster (${students.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 4,
                        children: [
                        TextButton.icon(
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: Colors.green,
                          ),
                          label: const Text(
                            'All Present',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              for (final s in students) {
                                _attendanceStatuses[s.id] = 'present';
                              }
                            });
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(
                            Icons.cancel_outlined,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            'All Absent',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              for (final s in students) {
                                _attendanceStatuses[s.id] = 'absent';
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
                const SizedBox(height: 8),

                ...students.map((student) {
                  final status =
                      _attendanceStatuses[student.id] ?? 'present';
                  return ClayCard(
                    depth: 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: ClayTokens.softLavender,
                              child: Text(
                                student.name.isNotEmpty
                                    ? student.name[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  color: ClayTokens.deepIndigo,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    student.email,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Choice chips for Present / Late / Absent
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text(
                                    'Present',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                selected: status == 'present',
                                selectedColor: Colors.green.shade100,
                                labelStyle: TextStyle(
                                  color: status == 'present'
                                      ? Colors.green.shade900
                                      : colors.onSurface,
                                  fontWeight: status == 'present'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setState(
                                      () => _attendanceStatuses[student.id] =
                                          'present',
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text(
                                    'Late',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                selected: status == 'late',
                                selectedColor: Colors.orange.shade100,
                                labelStyle: TextStyle(
                                  color: status == 'late'
                                      ? Colors.orange.shade900
                                      : colors.onSurface,
                                  fontWeight: status == 'late'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setState(
                                      () => _attendanceStatuses[student.id] =
                                          'late',
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text(
                                    'Absent',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                selected: status == 'absent',
                                selectedColor: Colors.red.shade100,
                                labelStyle: TextStyle(
                                  color: status == 'absent'
                                      ? Colors.red.shade900
                                      : colors.onSurface,
                                  fontWeight: status == 'absent'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setState(
                                      () => _attendanceStatuses[student.id] =
                                          'absent',
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 10),
                // Save attendance record button
                SizedBox(
                  width: double.infinity,
                  child: ClayButton(
                    onPressed: _isSavingAttendance
                        ? null
                        : () async {
                            setState(() => _isSavingAttendance = true);
                            try {
                              final records = students.map((s) {
                                return AttendanceRecordItem(
                                  studentUid: s.id,
                                  studentName: s.name,
                                  status:
                                      _attendanceStatuses[s.id] ?? 'present',
                                  remarks: _attendanceRemarks[s.id]?.text
                                          .trim() ??
                                      '',
                                );
                              }).toList();

                              final ok = await ref
                                  .read(homeRepositoryProvider)
                                  .takeAttendance(
                                    classId: widget.classroom.id,
                                    sessionDate: _attendanceDate,
                                    records: records,
                                    topic: _attendanceTopicCtrl.text
                                            .trim()
                                            .isEmpty
                                        ? 'Regular Session'
                                        : _attendanceTopicCtrl.text.trim(),
                                  );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Attendance recorded successfully!'
                                          : 'Failed to record attendance.',
                                    ),
                                    backgroundColor: ok
                                        ? ClayTokens.mintDark
                                        : Colors.red,
                                  ),
                                );
                              }
                              setState(() {
                                _isSavingAttendance = false;
                                _attendanceRefreshKey++;
                              });
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ErrorMessageHelper.format(e, fallback: 'Error saving attendance. Please try again.')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              setState(() => _isSavingAttendance = false);
                            }
                          },
                    child: Center(
                      child: _isSavingAttendance
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Attendance Record',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),
        // Past Classroom Attendance History
        const Text(
          'Past Attendance Sessions',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<AttendanceSession>>(
          key: ValueKey(_attendanceRefreshKey),
          future: ref
              .read(homeRepositoryProvider)
              .getClassAttendance(widget.classroom.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final sessions = snapshot.data ?? [];
            if (sessions.isEmpty) {
              return ClayCard(
                depth: 1,
                padding: const EdgeInsets.all(14),
                child: Center(
                  child: Text(
                    'No past attendance records found for this class.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: sessions.map((s) {
                final dateStr =
                    '${s.sessionDate.year}-${s.sessionDate.month.toString().padLeft(2, '0')}-${s.sessionDate.day.toString().padLeft(2, '0')}';
                return ClayCard(
                  depth: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_note_rounded,
                        color: ClayTokens.deepIndigo,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.topic.isNotEmpty ? s.topic : 'Session',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 4,
                        children: [
                          ClayBadge(
                            label: '${s.presentCount}P',
                            backgroundColor: Colors.green.shade50,
                            textColor: Colors.green.shade800,
                          ),
                          ClayBadge(
                            label: '${s.lateCount}L',
                            backgroundColor: Colors.orange.shade50,
                            textColor: Colors.orange.shade800,
                          ),
                          ClayBadge(
                            label: '${s.absentCount}A',
                            backgroundColor: Colors.red.shade50,
                            textColor: Colors.red.shade800,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStudentAttendanceSection(
    BuildContext context,
    String studentUid,
  ) {
    final colors = Theme.of(context).colorScheme;

    return FutureBuilder<StudentAttendanceSummary>(
      future:
          ref.read(homeRepositoryProvider).getStudentAttendance(studentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final summary = snapshot.data ??
            const StudentAttendanceSummary(
              totalSessions: 0,
              presentCount: 0,
              absentCount: 0,
              lateCount: 0,
              percentage: 100,
            );

        final pctColor = summary.percentage >= 80
            ? Colors.green
            : (summary.percentage >= 65 ? Colors.orange : Colors.red);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClayCard(
              depth: 3,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Attendance Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Overall standing across all classes',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: pctColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: pctColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '${summary.percentage}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: pctColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricMiniCard(
                          context,
                          label: 'Total',
                          value: '${summary.totalSessions}',
                          color: ClayTokens.deepIndigo,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricMiniCard(
                          context,
                          label: 'Present',
                          value: '${summary.presentCount}',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricMiniCard(
                          context,
                          label: 'Late',
                          value: '${summary.lateCount}',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricMiniCard(
                          context,
                          label: 'Absent',
                          value: '${summary.absentCount}',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Session Records (${summary.sessions.length})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 10),
            if (summary.sessions.isEmpty)
              ClayCard(
                depth: 1,
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No attendance session history recorded yet.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              ...summary.sessions.map((sess) {
                final status =
                    (sess['status'] ?? 'present').toString().toLowerCase();
                final badgeColor = status == 'present'
                    ? Colors.green
                    : (status == 'late' ? Colors.orange : Colors.red);
                final topic = sess['topic']?.toString() ?? 'Class Session';
                final date =
                    sess['sessionDate']?.toString().split('T').first ?? '';

                return ClayCard(
                  depth: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        status == 'present'
                            ? Icons.check_circle_rounded
                            : (status == 'late'
                                ? Icons.access_time_rounded
                                : Icons.cancel_rounded),
                        color: badgeColor,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            if (date.isNotEmpty)
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      ClayBadge(
                        label: status.toUpperCase(),
                        backgroundColor: badgeColor.withValues(alpha: 0.15),
                        textColor: badgeColor,
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildMetricMiniCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection(BuildContext context, bool isTeacher) {
    final colors = Theme.of(context).colorScheme;
    final currentUser = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ML Spam Protected Classroom Chat Header Card
        ClayCard(
          depth: 2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.security_rounded, size: 18, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ML Spam Filter Active · Secure Channel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: 'Refresh messages',
                onPressed: () => setState(() => _chatRefreshKey++),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Message List
        FutureBuilder<List<ChatMessageItem>>(
          key: ValueKey(_chatRefreshKey),
          future: ref
              .read(homeRepositoryProvider)
              .getClassMessages(widget.classroom.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final messages = snapshot.data ?? [];
            if (messages.isEmpty) {
              return ClayCard(
                depth: 1,
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 36),
                      const SizedBox(height: 10),
                      Text(
                        'No messages yet.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start the classroom conversation below!',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: messages.map((msg) {
                final isMe = currentUser != null &&
                    (currentUser.id == msg.senderUid ||
                        currentUser.name == msg.senderName);
                final timeStr =
                    '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

                return ClayCard(
                  depth: isMe ? 3 : 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: msg.isTeacher
                                      ? ClayTokens.softLavender
                                      : Colors.blue.shade50,
                                  child: Text(
                                    msg.senderName.isNotEmpty
                                        ? msg.senderName[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: msg.isTeacher
                                          ? ClayTokens.deepIndigo
                                          : Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    msg.senderName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ClayBadge(
                                  label: msg.isTeacher ? 'TEACHER' : 'STUDENT',
                                  backgroundColor: msg.isTeacher
                                      ? ClayTokens.softLavender
                                      : Colors.blue.shade50,
                                  textColor: msg.isTeacher
                                      ? ClayTokens.deepIndigo
                                      : Colors.blue.shade800,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 12),

        // Message input row with ML spam check
        ClayCard(
          depth: 3,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Type a classroom message...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _sendClassroomChat(context),
                ),
              ),
              IconButton(
                icon: _isSendingChat
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: ClayTokens.deepIndigo,
                      ),
                onPressed:
                    _isSendingChat ? null : () => _sendClassroomChat(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendClassroomChat(BuildContext context) async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty || _isSendingChat) return;

    final currentUser = ref.read(currentUserProvider);
    final isTeacher = ref.read(isTeacherProvider);
    final homeRepo = ref.read(homeRepositoryProvider);

    setState(() => _isSendingChat = true);

    try {
      // 1. ML Spam Filter Pre-flight Check
      final spamCheck = await homeRepo.checkSpam(
        meetingId: widget.classroom.id,
        userId: currentUser?.id ?? 'student-mock-1',
        message: text,
      );

      if (spamCheck.isSpam) {
        if (context.mounted) {
          final reasonsMsg = spamCheck.reasons.isNotEmpty
              ? spamCheck.reasons.join(', ')
              : 'Spam detected';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Message blocked by spam filter: $reasonsMsg'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isSendingChat = false);
        return;
      }

      // 2. Send message
      await homeRepo.sendChatMessage(
        classId: widget.classroom.id,
        text: text,
        senderUid: currentUser?.id ?? 'student-mock-1',
        senderName: currentUser?.name ?? (isTeacher ? 'Teacher' : 'Student'),
        senderRole: isTeacher ? 'teacher' : 'student',
      );

      _chatCtrl.clear();
      setState(() {
        _isSendingChat = false;
        _chatRefreshKey++;
      });
    } catch (e) {
      if (context.mounted) {
        final errorText = e is ClassroomException
            ? e.message
            : ErrorMessageHelper.format(e, fallback: 'Message not sent');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isSendingChat = false);
    }
  }

  Future<void> _joinLiveVideoCall(BuildContext context, bool isTeacher) async {
    final classroom = widget.classroom;
    final authRepo = ref.read(authRepositoryProvider);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final dio = DioClient.createFor(
        ApiConfig.coreBaseUrl,
        tokenReader: () => authRepo.getIdToken(),
      );

      final response = await dio.post<Map<String, dynamic>>(
        '/api/classrooms/${classroom.id}/meeting/token',
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final token = data['token'] as String;
        final serverUrl = data['serverUrl'] as String;
        final roomName = data['roomName'] as String? ?? classroom.name;

        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LiveMeetingScreen(
                serverUrl: serverUrl,
                token: token,
                roomTitle: roomName,
                isTeacher: isTeacher,
              ),
            ),
          );
        }
      }
    } on DioException catch (dioErr) {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
      }

      final resData = dioErr.response?.data;
      if (resData is Map && resData['status'] == 'awaiting_credentials') {
        if (context.mounted) {
          _showLiveKitConfigDialog(context);
        }
        return;
      }

      final msg = (resData is Map && resData['message'] != null)
          ? resData['message'] as String
          : 'LiveKit server unavailable. Check your backend configuration.';

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMessageHelper.format(e, fallback: 'Error connecting to meeting. Please try again.'))),
        );
      }
    }
  }

  void _showLiveKitConfigDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.videocam_rounded, color: Colors.blueAccent, size: 36),
        title: const Text('LiveKit Video Integration Ready'),
        content: const Text(
          'LiveKit WebRTC client is integrated into the app. To start real two-way audio/video calls, add your free LiveKit Cloud credentials to the backend .env:\n\n'
          '• LIVEKIT_URL=wss://your-project.livekit.cloud\n'
          '• LIVEKIT_API_KEY=API...\n'
          '• LIVEKIT_API_SECRET=secret...\n\n'
          'Create a free project at https://cloud.livekit.io to enable live video calling.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.video_call_rounded, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayTokens.deepIndigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _copyMeetingLink(context, launch: true);
            },
            label: const Text('Join Jitsi Meeting Instead'),
          ),
        ],
      ),
    );
  }
}
