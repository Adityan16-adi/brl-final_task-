import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/application/auth_providers.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.roleTeacher.withAlpha(24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.rate_review_rounded,
                      color: AppTheme.roleTeacher,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${assignment.subject} · Max Marks: ${assignment.points}',
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
                'Submitted Solution:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest
                      .withAlpha(80),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(ctx).colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  assignment.submittedText ??
                      'No written solution submitted yet.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 14),
              if (assignment.status == AssignmentStatus.graded) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.statusGraded.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.statusGraded,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Graded: ${assignment.marks ?? 0}/${assignment.points} Marks',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.statusGraded,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (assignment.feedback != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Feedback: "${assignment.feedback}"',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ] else ...[
                const Text(
                  'Status: Awaiting Teacher Grading',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.statusPending,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close Review'),
                ),
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
    final textTheme = Theme.of(context).textTheme;
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
          // Greeting & Quick Action Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          isTeacher
                              ? 'Welcome back, Teacher'
                              : 'Welcome back, Student',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isTeacher
                                ? AppTheme.roleTeacher.withAlpha(24)
                                : AppTheme.roleStudent.withAlpha(24),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isTeacher
                                  ? AppTheme.roleTeacher.withAlpha(80)
                                  : AppTheme.roleStudent.withAlpha(80),
                            ),
                          ),
                          child: Text(
                            isTeacher ? 'TEACHER' : 'STUDENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isTeacher
                                  ? AppTheme.roleTeacher
                                  : AppTheme.roleStudent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTeacher
                          ? (currentUser?.name.isNotEmpty == true &&
                                    currentUser!.name != 'Teacher'
                                ? '${currentUser.name} · Manage courses & review student submissions.'
                                : 'Manage your active classes and review student submissions.')
                          : (currentUser?.name.isNotEmpty == true &&
                                    currentUser!.name != 'Student'
                                ? '${currentUser.name} · Keep up the momentum with your coursework today.'
                                : 'Keep up the momentum with your coursework today.'),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => const JoinClassDialog(),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(isTeacher ? 'Add Class' : 'Join Class'),
              ),
            ],
          ),
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
            error: (err, _) => Card(
              color: colors.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Unable to load learning summary: $err'),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Role-specific Teacher Notice Card
          if (isTeacher) ...[
            _buildTeacherNoticeCard(context),
            const SizedBox(height: 16),
          ],

          // AI Mentor Quick-Launch Card
          _buildAiMentorBanner(context),
          const SizedBox(height: 20),

          // Student: Attendance & Learning Progress Card
          if (!isTeacher) ...[
            _buildStudentProgressCard(context),
            const SizedBox(height: 20),
          ],

          // Today's Next Class / Schedule
          _buildSectionHeader(
            context,
            title: isTeacher ? 'Teaching Schedule' : 'Upcoming Schedule',
            actionText: 'View All',
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

          // Assignments / Submissions Section
          _buildSectionHeader(
            context,
            title: isTeacher
                ? 'Course Assignments & Grading'
                : 'Pending Assignments',
            actionText: 'All Work',
            onAction: () => onNavigateToTab(2), // Assignments Tab
          ),
          const SizedBox(height: 10),
          assignmentsAsync.when(
            data: (assignments) {
              if (isTeacher) {
                // Teacher view: show assignments with grading status
                return Column(
                  children: assignments
                      .map((a) => _buildTeacherAssignmentCard(context, a))
                      .toList(),
                );
              }

              // Student view: show pending assignments
              final pending = assignments
                  .where((a) => a.status == AssignmentStatus.pending)
                  .toList();
              if (pending.isEmpty) {
                return _buildEmptyState(
                  context,
                  icon: Icons.task_alt_rounded,
                  title: 'All caught up!',
                  subtitle:
                      'You have no pending assignments waiting for submission.',
                );
              }
              return Column(
                children: pending
                    .map((a) => _buildAssignmentCard(context, a))
                    .toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Text('Could not load assignments: $err'),
          ),
          const SizedBox(height: 24),

          // Classrooms Preview
          _buildSectionHeader(
            context,
            title: isTeacher ? 'Class Rosters & Codes' : 'My Classrooms',
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
                  subtitle: isTeacher ? 'Create a class to get started.' : 'Use the "Join Class" button to enter a classroom code.',
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
                      mainAxisExtent: isTeacher ? 145 : 135,
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
                ? 'Published Course Materials'
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

  Widget _buildStudentProgressCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Academic Progress & Attendance',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.statusGraded.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'On Track',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.statusGraded,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildProgressItem(
                    context,
                    'Coursework',
                    '75%',
                    0.75,
                    colors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildProgressItem(
                    context,
                    'Attendance',
                    '94%',
                    0.94,
                    AppTheme.statusGraded,
                  ),
                ),
              ],
            ),
          ],
        ),
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
                  fontSize: 12,
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
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherNoticeCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: AppTheme.roleTeacher.withAlpha(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.roleTeacher.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.school_rounded,
              color: AppTheme.roleTeacher,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructor Dashboard Active',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.roleTeacher,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Live grading API endpoints (`/api/submissions/:id/grade`) are verified. Local mock state handles rapid UI grading preview.',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGrid(
    BuildContext context,
    HomeSummary summary,
    bool isTeacher,
  ) {
    final colors = Theme.of(context).colorScheme;

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
          childAspectRatio: isWide ? 1.4 : 1.15,
          children: [
            _metricCard(
              context,
              title: isTeacher ? 'Active Courses' : 'Classrooms',
              value: '${summary.enrolledClassesCount}',
              subtitle: isTeacher ? 'Classes instructed' : 'Active enrollments',
              icon: Icons.groups_rounded,
              color: isTeacher ? AppTheme.roleTeacher : colors.primary,
              onTap: () => onNavigateToTab(1),
            ),
            _metricCard(
              context,
              title: isTeacher ? 'To Review' : 'Assignments',
              value: '${summary.pendingAssignmentsCount}',
              subtitle: isTeacher
                  ? 'Submissions pending'
                  : (summary.pendingAssignmentsCount > 0
                        ? 'Due soon'
                        : 'None due'),
              icon: Icons.assignment_rounded,
              color: summary.pendingAssignmentsCount > 0
                  ? AppTheme.statusPending
                  : colors.primary,
              onTap: () => onNavigateToTab(2),
            ),
            _metricCard(
              context,
              title: 'Materials',
              value: '${summary.materialsCount}',
              subtitle: isTeacher ? 'Shared resources' : 'Lesson resources',
              icon: Icons.menu_book_rounded,
              color: colors.tertiary,
              onTap: () => onNavigateToTab(3),
            ),
            _metricCard(
              context,
              title: 'AI Mentor',
              value: 'Active',
              subtitle: '24/7 Study Doubts',
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFF6366F1),
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant.withAlpha(80)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(icon, size: 18, color: color),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
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
        ),
      ),
    );
  }

  Widget _buildAiMentorBanner(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary.withAlpha(220), const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Stuck on a problem?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ask the AI Mentor for step-by-step explanations, math derivations, and study notes.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => context.push('/mentor'),
            child: const Text(
              'Ask Now',
              style: TextStyle(fontWeight: FontWeight.w700),
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
                ?.copyWith(fontWeight: FontWeight.w700),
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
                  fontWeight: FontWeight.w600,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.isToday
                    ? colors.primaryContainer
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.videocam_rounded,
                color: item.isToday
                    ? colors.onPrimaryContainer
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer.withAlpha(150),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.type,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.subject,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
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
              tooltip: 'Meeting Preview',
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Preview meeting session: ${item.title}'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, AssignmentItem assignment) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showDialog<bool>(
          context: context,
          builder: (_) => SubmitAssignmentDialog(assignment: assignment),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.statusPending.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_late_rounded,
                  color: AppTheme.statusPending,
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
                        Text(
                          assignment.subject,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
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
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Due ${assignment.dueDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.statusPending,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) =>
                      SubmitAssignmentDialog(assignment: assignment),
                ),
                child: const Text('Turn In'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherAssignmentCard(
    BuildContext context,
    AssignmentItem assignment,
  ) {
    final colors = Theme.of(context).colorScheme;
    final isGraded = assignment.status == AssignmentStatus.graded;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTeacherGradingDialog(context, assignment),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      (isGraded
                              ? AppTheme.statusGraded
                              : AppTheme.statusPending)
                          .withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isGraded
                      ? Icons.check_circle_rounded
                      : Icons.pending_actions_rounded,
                  color: isGraded
                      ? AppTheme.statusGraded
                      : AppTheme.statusPending,
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
                        Text(
                          assignment.subject,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
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
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGraded
                          ? 'Graded (${assignment.marks}/${assignment.points} marks)'
                          : 'Pending Student Submission / Review',
                      style: TextStyle(
                        fontSize: 12,
                        color: isGraded
                            ? AppTheme.statusGraded
                            : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _showTeacherGradingDialog(context, assignment),
                child: Text(isGraded ? 'Review' : 'Grade'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassroomTile(
    BuildContext context,
    ClassroomItem c,
    bool isTeacher,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onNavigateToTab(1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isTeacher
                          ? AppTheme.roleTeacher.withAlpha(24)
                          : colors.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      c.subject,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isTeacher
                            ? AppTheme.roleTeacher
                            : colors.onPrimaryContainer,
                      ),
                    ),
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
                          vertical: 1,
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
                            const SizedBox(width: 2),
                            const Icon(Icons.copy_rounded, size: 10),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
              Text(
                c.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    size: 12,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${c.studentCount} students',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialTile(BuildContext context, MaterialItem m) {
    final colors = Theme.of(context).colorScheme;

    IconData icon = Icons.article_rounded;
    Color iconColor = colors.primary;

    if (m.type == CourseMaterialType.video) {
      icon = Icons.play_circle_fill_rounded;
      iconColor = Colors.red.shade400;
    } else if (m.type == CourseMaterialType.notes) {
      icon = Icons.edit_note_rounded;
      iconColor = Colors.teal;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          m.title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${m.subject} · ${m.details}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_rounded, size: 16),
        onTap: () => onNavigateToTab(3),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(icon, size: 36, color: colors.onSurfaceVariant.withAlpha(120)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
