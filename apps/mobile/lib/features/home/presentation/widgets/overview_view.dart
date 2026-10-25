import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/clay_theme.dart';
import '../../../../core/widgets/demo_data_badge.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';
import '../screens/classroom_detail_screen.dart';
import 'create_assignment_dialog.dart';
import 'create_class_dialog.dart';
import 'join_class_dialog.dart';
import 'submit_assignment_dialog.dart';

class OverviewView extends ConsumerWidget {
  const OverviewView({required this.onNavigateToTab, super.key});

  final void Function(int tabIndex) onNavigateToTab;

  void _showTeacherGradingDialog(
    BuildContext context,
    AssignmentItem assignment,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClayContainer(
                    width: 44,
                    height: 44,
                    depth: 3,
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(14),
                    child: const Icon(
                      Icons.rate_review_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${assignment.subject} · Max Points: ${assignment.points}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Submitted Work:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 6),
              ClayContainer(
                width: double.infinity,
                depth: 3,
                padding: const EdgeInsets.all(14),
                child: Text(
                  assignment.submittedText ??
                      'No written solution submitted yet.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              if (assignment.status == AssignmentStatus.graded) ...[
                ClayContainer(
                  depth: 2,
                  color: ClayTokens.mint,
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(ClayTokens.radiusSmall),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: ClayTokens.mintDark,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Graded: ${assignment.marks ?? 0}/${assignment.points} Points',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ClayTokens.mintDark,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (assignment.feedback != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Instructor Feedback: "${assignment.feedback}"',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ] else ...[
                const ClayBadge(
                  label: 'Pending Instructor Review',
                  icon: Icons.hourglass_top_rounded,
                  backgroundColor: Color(0xFFFEF3C7),
                  textColor: Color(0xFFB45309),
                ),
              ],
              const SizedBox(height: 20),
              ClayButton(
                isFullWidth: true,
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close Review'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAttendanceModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final classrooms = ref.read(classroomsProvider).value ?? [];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(
                    Icons.fact_check_rounded,
                    color: ClayTokens.deepIndigo,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Classroom Rosters & Attendance',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'View active classroom rosters and enrolled learners. Select a classroom to inspect learners or start a live session.',
                style: TextStyle(
                  fontSize: 13,
                  color: ClayTokens.secondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              if (classrooms.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No classrooms created yet.')),
                ),
              ] else ...[
                ...classrooms.map((c) {
                  return ClayCard(
                    depth: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClassroomDetailScreen(classroom: c),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          color: ClayTokens.deepIndigo,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${c.subject} · ${c.studentCount} enrolled',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: ClayTokens.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 10),
              ClayButton(
                isFullWidth: true,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onNavigateToTab(1);
                },
                child: const Text('Manage All Classrooms'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeSummaryProvider);
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final scheduleAsync = ref.watch(scheduleProvider);
    final classroomsAsync = ref.watch(classroomsProvider);
    final materialsAsync = ref.watch(materialsProvider);
    final currentUser = ref.watch(currentUserProvider);

    final colors = Theme.of(context).colorScheme;
    final isTeacher = currentUser?.isTeacher == true;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(homeSummaryProvider);
        ref.invalidate(assignmentsProvider);
        ref.invalidate(scheduleProvider);
        ref.invalidate(classroomsProvider);
        ref.invalidate(materialsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Personalized Claymorphic Greeting Header
          _buildPersonalizedHeader(context, currentUser, isTeacher),
          const SizedBox(height: 18),

          // Role-specific Metric Grid
          summaryAsync.when(
            data: (summary) => _buildMetricGrid(context, summary, isTeacher),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => ClayCard(
              color: colors.errorContainer,
              child: Text('Unable to load learning summary: $err'),
            ),
          ),
          const SizedBox(height: 18),

          // Role-specific Teacher Notice Card
          if (isTeacher) ...[
            _buildTeacherNoticeCard(context),
            const SizedBox(height: 18),
          ],

          // Role-Specific Quick Actions Bar
          _buildQuickActionsBar(context, isTeacher, ref),
          const SizedBox(height: 18),

          // Student: Attendance & Learning Streak Progress Card
          if (!isTeacher) ...[
            _buildStudentProgressCard(
              context,
              assignmentsAsync,
              classroomsAsync,
            ),
            const SizedBox(height: 18),
          ],

          // AI Mentor Quick-Launch Clay Banner
          _buildAiMentorBanner(context),
          const SizedBox(height: 22),

          // Urgent Assignments / Grading Queue Section
          _buildSectionHeader(
            context,
            title: isTeacher
                ? 'Course Submissions & Grading'
                : 'Assignments & Deadlines',
            actionText: 'View All',
            onAction: () => onNavigateToTab(2), // Assignments Tab
          ),
          const SizedBox(height: 10),
          assignmentsAsync.when(
            data: (assignments) {
              if (isTeacher) {
                if (assignments.isEmpty) {
                  return _buildEmptyState(
                    context,
                    icon: Icons.task_alt_rounded,
                    title: 'No assignments created',
                    subtitle: 'Create your first assignment for your students.',
                  );
                }
                return Column(
                  children: assignments
                      .map((a) => _buildTeacherAssignmentCard(context, a))
                      .toList(),
                );
              }

              // Student view: prioritize pending assignments
              final pending = assignments
                  .where((a) => a.status == AssignmentStatus.pending)
                  .toList();
              final displayList = pending.isNotEmpty
                  ? pending
                  : assignments.take(3).toList();

              if (displayList.isEmpty) {
                return _buildEmptyState(
                  context,
                  icon: Icons.task_alt_rounded,
                  title: 'All caught up!',
                  subtitle:
                      'You have no pending assignments waiting for submission.',
                );
              }
              return Column(
                children: displayList
                    .map((a) => _buildAssignmentCard(context, a))
                    .toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Text('Could not load assignments: $err'),
          ),
          const SizedBox(height: 24),

          // Today's Next Class / Schedule
          _buildSectionHeader(
            context,
            title: isTeacher ? 'Teaching Timetable' : 'Upcoming Schedule',
            actionText: 'Full Schedule',
            onAction: () => onNavigateToTab(4), // Schedule Tab
          ),
          const SizedBox(height: 10),
          scheduleAsync.when(
            data: (schedules) {
              if (schedules.isEmpty) {
                return _buildEmptyState(
                  context,
                  icon: Icons.event_available_rounded,
                  title: 'No classes scheduled today',
                  subtitle: 'Enjoy your free time or prepare coursework.',
                );
              }
              final todayClasses = schedules.where((s) => s.isToday).toList();
              final displayList = todayClasses.isNotEmpty
                  ? todayClasses
                  : schedules.take(2).toList();

              return Column(
                children: displayList
                    .map((item) => _buildScheduleCard(context, item))
                    .toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Text('Could not load schedule: $err'),
          ),
          const SizedBox(height: 24),

          // Classrooms Preview
          _buildSectionHeader(
            context,
            title: isTeacher ? 'My Classrooms & Codes' : 'Enrolled Classrooms',
            actionText: 'All Classes',
            onAction: () => onNavigateToTab(1), // Classrooms Tab
          ),
          const SizedBox(height: 10),
          classroomsAsync.when(
            data: (classes) {
              if (classes.isEmpty) {
                return _buildEmptyState(
                  context,
                  icon: Icons.school_outlined,
                  title: 'No classrooms available',
                  subtitle: isTeacher
                      ? 'Tap "Create Class" to set up your first virtual classroom.'
                      : 'Use the "Join Code" button to enroll in your first course.',
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: isTeacher ? 150 : 138,
                    ),
                    itemCount: classes.length.clamp(0, 4),
                    itemBuilder: (context, index) {
                      final c = classes[index];
                      return _buildClassroomTile(context, c, isTeacher);
                    },
                  );
                },
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Text('Could not load classrooms: $err'),
          ),
          const SizedBox(height: 24),

          // Recent Learning Materials
          _buildSectionHeader(
            context,
            title: isTeacher
                ? 'Published Study Materials'
                : 'Recent Learning Materials',
            actionText: 'Library',
            onAction: () => onNavigateToTab(3), // Materials Tab
          ),
          const SizedBox(height: 10),
          materialsAsync.when(
            data: (materials) {
              if (materials.isEmpty) {
                return _buildEmptyState(
                  context,
                  icon: Icons.menu_book_outlined,
                  title: 'No materials shared yet',
                  subtitle:
                      'Study notes and lesson recordings will appear here.',
                );
              }
              return Column(
                children: materials
                    .take(3)
                    .map((m) => _buildMaterialTile(context, m))
                    .toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Text('Could not load materials: $err'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherNoticeCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClayCard(
      depth: 4,
      color: isDark ? ClayTokens.darkCard : const Color(0xFFFBF8FF),
      padding: const EdgeInsets.all(14),
      child: const Row(
        children: [
          Icon(Icons.school_rounded, color: Color(0xFF8B5CF6), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructor Dashboard Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Live grading API endpoints verified. Local state manages rapid classroom reviews.',
                  style: TextStyle(
                    fontSize: 11,
                    color: ClayTokens.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedHeader(
    BuildContext context,
    AppUser? user,
    bool isTeacher,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = user?.name.isNotEmpty == true
        ? user!.name
        : (isTeacher ? 'Teacher' : 'Student');

    return ClayCard(
      depth: 6,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ClayContainer(
            width: 52,
            height: 52,
            depth: 4,
            gradient: LinearGradient(
              colors: isTeacher
                  ? [const Color(0xFF9333EA), const Color(0xFF6B21A8)]
                  : [const Color(0xFF6356F5), const Color(0xFF473BB8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isTeacher
                            ? 'Welcome back, Teacher'
                            : 'Welcome back, Student',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user?.isDemo == true ||
                        user?.email.contains('@demo.com') == true) ...[
                      const ClayBadge(
                        label: 'DEMO DATA',
                        backgroundColor: Color(0xFFFEF3C7),
                        textColor: Color(0xFF92400E),
                      ),
                      const SizedBox(width: 6),
                    ],
                    ClayBadge(
                      label: isTeacher ? 'TEACHER' : 'STUDENT',
                      backgroundColor: isTeacher
                          ? (isDark
                                ? const Color(0xFF382650)
                                : const Color(0xFFF3E8FF))
                          : (isDark
                                ? const Color(0xFF2E2B54)
                                : ClayTokens.softLavender),
                      textColor: isTeacher
                          ? const Color(0xFF8B5CF6)
                          : ClayTokens.deepIndigo,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isTeacher
                      ? 'Rosters updated · Course submissions ready for grading'
                      : '🔥 5-Day Study Streak · 2 assignments due this week',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : ClayTokens.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsBar(
    BuildContext context,
    bool isTeacher,
    WidgetRef ref,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isTeacher) {
          return Row(
            children: [
              Expanded(
                child: ClayButton(
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: () async {
                    final res = await showDialog<dynamic>(
                      context: context,
                      builder: (_) => const CreateClassDialog(),
                    );
                    if (res is ClassroomItem && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClassroomDetailScreen(classroom: res),
                        ),
                      );
                    }
                  },
                  child: const Text('Create Class'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClayButton(
                  icon: Icons.post_add_rounded,
                  color: const Color(0xFF0D9488),
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => const CreateAssignmentDialog(),
                  ),
                  child: const Text('Add Assignment'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClayButton(
                  icon: Icons.fact_check_outlined,
                  color: const Color(0xFF7C3AED),
                  onPressed: () => _showAttendanceModal(context, ref),
                  child: const Text('Attendance'),
                ),
              ),
            ],
          );
        }

        // Student quick actions
        return Row(
          children: [
            Expanded(
              child: ClayButton(
                icon: Icons.vpn_key_rounded,
                onPressed: () async {
                  final res = await showDialog<dynamic>(
                    context: context,
                    builder: (_) => const JoinClassDialog(),
                  );
                  if (res is ClassroomItem && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClassroomDetailScreen(classroom: res),
                      ),
                    );
                  }
                },
                child: const Text('Join Class'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClayButton(
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFF6356F5),
                onPressed: () => context.push('/mentor'),
                child: const Text('Ask Mentor'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClayButton(
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF0D9488),
                onPressed: () => onNavigateToTab(4),
                child: const Text('Schedule'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStudentProgressCard(
    BuildContext context,
    AsyncValue<List<AssignmentItem>> assignmentsAsync,
    AsyncValue<List<ClassroomItem>> classroomsAsync,
  ) {
    final assignments = assignmentsAsync.value ?? [];
    final classrooms = classroomsAsync.value ?? [];
    final total = assignments.length;
    final completed = assignments
        .where((a) => a.status != AssignmentStatus.pending)
        .length;
    final progress = total > 0 ? (completed / total) : 0.0;
    final progressPct = (progress * 100).toInt();

    return ClayCard(
      depth: 5,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClayContainer(
                width: 36,
                height: 36,
                depth: 3,
                color: ClayTokens.softLavender,
                borderRadius: BorderRadius.circular(12),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 20,
                  color: ClayTokens.deepIndigo,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Academic Progress & Attendance',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ClayBadge(
                label: total > 0 ? '$progressPct% Completed' : 'Enrolled',
                backgroundColor: ClayTokens.mint,
                textColor: ClayTokens.mintDark,
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildProgressItem(
                  context,
                  'Coursework Completion',
                  '$progressPct%',
                  progress,
                  ClayTokens.deepIndigo,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressItem(
                  context,
                  'Class Enrollment',
                  '${classrooms.length} Enrolled',
                  classrooms.isNotEmpty ? 1.0 : 0.0,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    BuildContext context,
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(ClayTokens.radiusPill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricGrid(
    BuildContext context,
    HomeSummary summary,
    bool isTeacher,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final count = isWide ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWide ? 1.4 : 1.25,
          children: [
            _metricCard(
              context,
              title: isTeacher ? 'Active Courses' : 'Classrooms',
              value: '${summary.enrolledClassesCount}',
              subtitle: isTeacher ? 'Classes instructed' : 'Active enrollments',
              icon: Icons.groups_rounded,
              color: isTeacher
                  ? const Color(0xFF8B5CF6)
                  : ClayTokens.deepIndigo,
              onTap: () => onNavigateToTab(1),
            ),
            _metricCard(
              context,
              title: isTeacher ? 'To Review' : 'Assignments',
              value: '${summary.pendingAssignmentsCount}',
              subtitle: isTeacher
                  ? 'Submissions pending'
                  : (summary.pendingAssignmentsCount > 0
                        ? 'Due this week'
                        : 'All submitted'),
              icon: Icons.assignment_rounded,
              color: summary.pendingAssignmentsCount > 0
                  ? ClayTokens.peachDark
                  : const Color(0xFF10B981),
              onTap: () => onNavigateToTab(2),
            ),
            _metricCard(
              context,
              title: 'Study Materials',
              value: '${summary.materialsCount}',
              subtitle: isTeacher ? 'Resources shared' : 'Notes & recordings',
              icon: Icons.menu_book_rounded,
              color: const Color(0xFF0EA5E9),
              onTap: () => onNavigateToTab(3),
            ),
            _metricCard(
              context,
              title: 'AI Mentor',
              value: 'Active',
              subtitle: '24/7 Smart Doubts',
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFF6356F5),
              onTap: () => context.push('/mentor'),
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return ClayCard(
      depth: 5,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              ClayContainer(
                width: 28,
                height: 28,
                depth: 2,
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                padding: EdgeInsets.zero,
                child: Center(child: Icon(icon, size: 16, color: color)),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildAiMentorBanner(BuildContext context) {
    return ClayContainer(
      depth: 6,
      gradient: const LinearGradient(
        colors: [Color(0xFF5B4DF0), Color(0xFF4334C4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ClayContainer(
            width: 46,
            height: 46,
            depth: 4,
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stuck on a problem?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Ask the AI Mentor for step-by-step guidance, math derivations, and instant study notes.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ClayTokens.deepIndigo,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ClayTokens.radiusSmall),
              ),
            ),
            onPressed: () => context.push('/mentor'),
            child: const Text(
              'Ask Now',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String actionText,
    required VoidCallback onAction,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionText,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(BuildContext context, ScheduleItem item) {
    final colors = Theme.of(context).colorScheme;

    return ClayCard(
      depth: 5,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClayContainer(
            width: 44,
            height: 44,
            depth: 3,
            color: item.isToday
                ? ClayTokens.softLavender
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            child: Icon(
              Icons.videocam_rounded,
              color: item.isToday
                  ? ClayTokens.deepIndigo
                  : colors.onSurfaceVariant,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClayBadge(
                      label: item.type,
                      fontSize: 10,
                      backgroundColor: ClayTokens.mint,
                      textColor: ClayTokens.mintDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.subject,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.time,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy Session Preview Link',
            icon: const Icon(Icons.link_rounded, size: 20),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text: 'https://unified-learn.preview/live/${item.title}',
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Session link copied for "${item.title}"!'),
                  backgroundColor: ClayTokens.deepIndigo,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, AssignmentItem assignment) {
    final colors = Theme.of(context).colorScheme;

    return ClayCard(
      depth: 5,
      onTap: () => showDialog<bool>(
        context: context,
        builder: (_) => SubmitAssignmentDialog(assignment: assignment),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClayContainer(
            width: 44,
            height: 44,
            depth: 3,
            color: ClayTokens.softPeach,
            borderRadius: BorderRadius.circular(14),
            child: const Icon(
              Icons.assignment_late_rounded,
              color: ClayTokens.peachDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        assignment.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '·  ${assignment.points} Points',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  assignment.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Due: ${assignment.dueDate}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ClayTokens.peachDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => SubmitAssignmentDialog(assignment: assignment),
            ),
            child: const Text('Turn In'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherAssignmentCard(
    BuildContext context,
    AssignmentItem assignment,
  ) {
    final colors = Theme.of(context).colorScheme;
    final isGraded = assignment.status == AssignmentStatus.graded;

    return ClayCard(
      depth: 5,
      onTap: () => _showTeacherGradingDialog(context, assignment),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClayContainer(
            width: 44,
            height: 44,
            depth: 3,
            color: isGraded ? ClayTokens.mint : ClayTokens.softLavender,
            borderRadius: BorderRadius.circular(14),
            child: Icon(
              isGraded
                  ? Icons.check_circle_rounded
                  : Icons.pending_actions_rounded,
              color: isGraded ? ClayTokens.mintDark : ClayTokens.deepIndigo,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        assignment.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '·  Max: ${assignment.points} Pts',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  assignment.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isGraded
                      ? 'Graded (${assignment.marks}/${assignment.points} marks)'
                      : 'Pending Student Review / Grading',
                  style: TextStyle(
                    fontSize: 12,
                    color: isGraded
                        ? ClayTokens.mintDark
                        : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => _showTeacherGradingDialog(context, assignment),
            child: Text(isGraded ? 'Review' : 'Grade'),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomTile(
    BuildContext context,
    ClassroomItem c,
    bool isTeacher,
  ) {
    final colors = Theme.of(context).colorScheme;

    return ClayCard(
      depth: 4,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClassroomDetailScreen(classroom: c),
          ),
        );
      },
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClayBadge(
                label: c.subject,
                fontSize: 9,
                backgroundColor: isTeacher
                    ? const Color(0xFFF3E8FF)
                    : ClayTokens.softLavender,
                textColor: isTeacher
                    ? const Color(0xFF8B5CF6)
                    : ClayTokens.deepIndigo,
              ),
              if (c.code != null) ...[
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: c.code!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Class code ${c.code} copied to clipboard!',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c.code!,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.copy_rounded, size: 10),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ],
          ),
          Text(
            c.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          Row(
            children: [
              Icon(
                Icons.people_alt_outlined,
                size: 13,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${c.studentCount} students',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialTile(BuildContext context, MaterialItem m) {
    IconData icon = Icons.article_rounded;
    Color iconColor = ClayTokens.deepIndigo;

    if (m.type == CourseMaterialType.video) {
      icon = Icons.play_circle_fill_rounded;
      iconColor = Colors.redAccent;
    } else if (m.type == CourseMaterialType.notes) {
      icon = Icons.edit_note_rounded;
      iconColor = const Color(0xFF0D9488);
    }

    return ClayCard(
      depth: 4,
      onTap: () => onNavigateToTab(3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          ClayContainer(
            width: 38,
            height: 38,
            depth: 2,
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            padding: EdgeInsets.zero,
            child: Center(child: Icon(icon, color: iconColor, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${m.subject} · ${m.details}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, size: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colors = Theme.of(context).colorScheme;

    return ClayCard(
      depth: 3,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          Icon(
            icon,
            size: 36,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
  }
}
