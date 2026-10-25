import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/clay_theme.dart';
import '../../../auth/application/auth_providers.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';
import '../widgets/submit_assignment_dialog.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen>
    with SingleTickerProviderStateMixin {
  static const Color _coral = Color(0xFFEF4444);
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCountdown(DateTime? due) {
    if (due == null) return 'No due date';
    final now = DateTime.now();
    final difference = due.difference(now);

    if (difference.isNegative) {
      final days = difference.inDays.abs();
      if (days == 0) {
        final hours = difference.inHours.abs();
        return hours <= 1 ? 'Overdue (< 1h ago)' : 'Overdue by ${hours}h';
      }
      return 'Overdue by ${days}d';
    } else {
      final days = difference.inDays;
      if (days == 0) {
        final hours = difference.inHours;
        return hours <= 1 ? 'Due in < 1 hour!' : 'Due in ${hours}h';
      } else if (days == 1) {
        return 'Due tomorrow';
      } else if (days < 7) {
        return 'Due in $days days';
      } else {
        return 'Due in ${(days / 7).floor()} weeks';
      }
    }
  }

  Color _getUrgencyColor(DateTime? due, bool isDone) {
    if (isDone) return ClayTokens.mintDark;
    if (due == null) return ClayTokens.deepIndigo;
    final now = DateTime.now();
    if (due.isBefore(now)) return _coral;
    if (due.difference(now).inHours <= 24) return const Color(0xFFF59E0B);
    if (due.difference(now).inDays <= 7) return const Color(0xFF3B82F6);
    return ClayTokens.deepIndigo;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final isTeacher = ref.watch(isTeacherProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner & To-Do'),
        actions: [
          IconButton(
            tooltip: 'Refresh Assignments',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(assignmentsProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ClayTokens.deepIndigo,
          unselectedLabelColor:
              isDark ? Colors.white60 : ClayTokens.secondaryText,
          indicatorColor: ClayTokens.deepIndigo,
          tabs: const [
            Tab(icon: Icon(Icons.priority_high_rounded, size: 18), text: 'Urgent & Active'),
            Tab(icon: Icon(Icons.checklist_rounded, size: 18), text: 'All Tasks'),
            Tab(icon: Icon(Icons.done_all_rounded, size: 18), text: 'Completed'),
          ],
        ),
      ),
      body: assignmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: _coral),
                const SizedBox(height: 12),
                Text('Failed to load study plan: $err',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ClayButton(
                  onPressed: () => ref.invalidate(assignmentsProvider),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (assignments) {
          final now = DateTime.now();

          // Calculate counts
          final overdueCount = assignments.where((a) {
            final due = DateTime.tryParse(a.dueDate);
            final isDone = a.status == AssignmentStatus.submitted ||
                a.status == AssignmentStatus.graded;
            return !isDone && due != null && due.isBefore(now);
          }).length;

          final completedCount = assignments.where((a) {
            return a.status == AssignmentStatus.submitted ||
                a.status == AssignmentStatus.graded;
          }).length;

          final pendingCount = assignments.length - completedCount;

          return Column(
            children: [
              // Metric Quick Stats Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ClayCard(
                        depth: 3,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                        color: isDark
                            ? ClayTokens.darkCard
                            : const Color(0xFFEFF6FF),
                        child: Column(
                          children: [
                            Text(
                              '$pendingCount',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Pending',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClayCard(
                        depth: 3,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                        color: isDark
                            ? ClayTokens.darkCard
                            : const Color(0xFFFEF2F2),
                        child: Column(
                          children: [
                            Text(
                              '$overdueCount',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _coral,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Overdue',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClayCard(
                        depth: 3,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                        color: isDark
                            ? ClayTokens.darkCard
                            : const Color(0xFFF0FDF4),
                        child: Column(
                          children: [
                            Text(
                              '$completedCount',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: ClayTokens.mintDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Done',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search tasks, subjects, topics...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? ClayTokens.darkCard
                        : const Color(0xFFF1F0F7),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),

              // TabBar View of Lists
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Urgent & Active (sorted by due date asc, excluding completed)
                    _buildAssignmentList(
                      assignments.where((a) {
                        final isDone = a.status == AssignmentStatus.submitted ||
                            a.status == AssignmentStatus.graded;
                        if (isDone) return false;
                        if (_searchQuery.isEmpty) return true;
                        return a.title.toLowerCase().contains(_searchQuery) ||
                            a.subject.toLowerCase().contains(_searchQuery);
                      }).toList()
                        ..sort((a, b) {
                          final aDue = DateTime.tryParse(a.dueDate) ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          final bDue = DateTime.tryParse(b.dueDate) ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          return aDue.compareTo(bDue);
                        }),
                      emptyMessage: 'No urgent or active tasks! You are all caught up.',
                      isTeacher: isTeacher,
                    ),

                    // Tab 2: All Tasks
                    _buildAssignmentList(
                      assignments.where((a) {
                        if (_searchQuery.isEmpty) return true;
                        return a.title.toLowerCase().contains(_searchQuery) ||
                            a.subject.toLowerCase().contains(_searchQuery);
                      }).toList(),
                      emptyMessage: 'No assignments found.',
                      isTeacher: isTeacher,
                    ),

                    // Tab 3: Completed (Submitted or Graded)
                    _buildAssignmentList(
                      assignments.where((a) {
                        final isDone = a.status == AssignmentStatus.submitted ||
                            a.status == AssignmentStatus.graded;
                        if (!isDone) return false;
                        if (_searchQuery.isEmpty) return true;
                        return a.title.toLowerCase().contains(_searchQuery) ||
                            a.subject.toLowerCase().contains(_searchQuery);
                      }).toList(),
                      emptyMessage: 'No completed assignments yet.',
                      isTeacher: isTeacher,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAssignmentList(
    List<AssignmentItem> items, {
    required String emptyMessage,
    required bool isTeacher,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 48, color: ClayTokens.mintDark),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: ClayTokens.secondaryText),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final due = DateTime.tryParse(item.dueDate);
        final isDone = item.status == AssignmentStatus.submitted ||
            item.status == AssignmentStatus.graded;
        final countdownText = _formatCountdown(due);
        final urgencyColor = _getUrgencyColor(due, isDone);

        return ClayCard(
          depth: 3,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClayContainer(
                    width: 38,
                    height: 38,
                    depth: 2,
                    color: urgencyColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    child: Icon(
                      isDone
                          ? Icons.task_alt_rounded
                          : Icons.assignment_rounded,
                      color: urgencyColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subject,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ClayTokens.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: urgencyColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      countdownText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: urgencyColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: ClayTokens.deepIndigo.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.points} pts',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: ClayTokens.deepIndigo,
                          ),
                        ),
                      ),
                      if (item.status == AssignmentStatus.graded &&
                          item.marks != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: ClayTokens.mint.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Score: ${item.marks}/${item.points}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: ClayTokens.mintDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!isTeacher && !isDone)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ClayTokens.deepIndigo,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final res = await showDialog<bool>(
                          context: context,
                          builder: (_) =>
                              SubmitAssignmentDialog(assignment: item),
                        );
                        if (res == true) {
                          ref.invalidate(assignmentsProvider);
                        }
                      },
                      icon: const Icon(Icons.upload_file_rounded, size: 14),
                      label: const Text('Submit',
                          style: TextStyle(fontSize: 12)),
                    )
                  else if (!isTeacher && isDone)
                    Text(
                      item.status == AssignmentStatus.graded
                          ? 'Graded'
                          : 'Submitted',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ClayTokens.mintDark,
                      ),
                    ),
                ],
              ),
              if (item.feedback != null && item.feedback!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Teacher Remarks: ${item.feedback}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
