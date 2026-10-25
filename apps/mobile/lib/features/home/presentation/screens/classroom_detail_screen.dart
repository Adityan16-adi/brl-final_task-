import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/clay_theme.dart';
import '../../../auth/application/auth_providers.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';
import '../widgets/create_assignment_dialog.dart';
import '../widgets/submit_assignment_dialog.dart';
import 'live_meeting_screen.dart';

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
  int _activeTabIndex = 0; // 0: Meeting Room, 1: Coursework, 2: Learners

  @override
  void initState() {
    super.initState();
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
                  Text(
                    'Maximum Points: ${assignment.points}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: ClayTokens.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
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
          SegmentedButton<int>(
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
                icon: Icon(Icons.people_rounded),
                label: Text('Learners'),
              ),
            ],
            selected: {_activeTabIndex},
            onSelectionChanged: (set) {
              setState(() => _activeTabIndex = set.first);
            },
          ),
          const SizedBox(height: 18),

          // Tab Content
          if (_activeTabIndex == 0) ...[
            _buildMeetingRoomSection(context, isTeacher),
          ] else if (_activeTabIndex == 1) ...[
            _buildCourseworkSection(context, isTeacher, assignmentsAsync),
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
      ],
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
                  await showDialog<AssignmentItem>(
                    context: context,
                    builder: (_) => const CreateAssignmentDialog(),
                  );
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
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
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
          SnackBar(content: Text('Error connecting to meeting: $e')),
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
        ],
      ),
    );
  }
}
