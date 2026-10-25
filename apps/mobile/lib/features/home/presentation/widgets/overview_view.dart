import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/clay_theme.dart';
import '../../../../core/widgets/demo_data_badge.dart';
import '../../../auth/application/auth_providers.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';
import '../screens/classroom_detail_screen.dart';
import 'create_class_dialog.dart';
import 'join_class_dialog.dart';
import 'submit_assignment_dialog.dart';

/// Clean, uncluttered Dashboard Overview for Pragti students and teachers.
class OverviewView extends ConsumerStatefulWidget {
  const OverviewView({required this.onNavigateToTab, super.key});

  final void Function(int tabIndex) onNavigateToTab;

  @override
  ConsumerState<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends ConsumerState<OverviewView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGreeting(String? fullName) {
    final hour = DateTime.now().hour;
    final timeStr = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final firstName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim().split(' ').first
        : 'Student';
    return '$timeStr, $firstName';
  }

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
              Text(
                assignment.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              Text(
                '${assignment.subject} · Max Points: ${assignment.points}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    widget.onNavigateToTab(2); // Go to Assignments tab
                  },
                  child: const Text('View All Submissions'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isTeacher = currentUser?.isTeacher == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final summaryAsync = ref.watch(homeSummaryProvider);
    final classroomsAsync = ref.watch(classroomsProvider);
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final materialsAsync = ref.watch(materialsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(homeSummaryProvider);
        ref.invalidate(classroomsProvider);
        ref.invalidate(assignmentsProvider);
        ref.invalidate(materialsProvider);
        ref.invalidate(scheduleProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // 1. Top Header: Small greeting, avatar on the right, search toggle. No badges.
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(currentUser?.name),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTeacher
                          ? 'Instructor Dashboard Active'
                          : 'Welcome back to your classes',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : ClayTokens.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _isSearchOpen ? 'Close search' : 'Search',
                icon: Icon(_isSearchOpen ? Icons.close_rounded : Icons.search_rounded),
                onPressed: () {
                  setState(() {
                    _isSearchOpen = !_isSearchOpen;
                    if (!_isSearchOpen) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  });
                },
              ),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push('/account'),
                child: currentUser?.avatarUrl != null && currentUser!.avatarUrl!.isNotEmpty
                    ? CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(currentUser.avatarUrl!),
                      )
                    : Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isTeacher ? const Color(0xFF8B5CF6) : ClayTokens.brightBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (currentUser?.name.isNotEmpty == true)
                                ? currentUser!.name[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),

          // Offline Demo Mode Notification (Quiet banner only when in demo mode)
          if (currentUser?.isDemo == true) ...[
            const SizedBox(height: 12),
            const DemoDataBadge(
              message: 'DEMO DATA',
              compact: true,
            ),
          ],

          // Expandable Search Input
          if (_isSearchOpen) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? theme.colorScheme.outlineVariant
                      : const Color(0xFFCBD5E1),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 20, color: ClayTokens.brightBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Search classes, assignments, materials...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // If searching, render search results
          if (_searchQuery.isNotEmpty) ...[
            _buildSearchResults(
              context,
              classroomsAsync,
              assignmentsAsync,
              materialsAsync,
            ),
          ] else ...[
            // 2. One Prominent "Next Class" Card (or empty state with "Join a class")
            classroomsAsync.when(
              data: (classrooms) => _buildNextClassCard(
                context,
                classrooms,
                summaryAsync.value,
                isTeacher,
                isDark,
              ),
              loading: () => Container(
                height: 120,
                decoration: BoxDecoration(
                  color: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, _) => _buildNextClassCard(
                context,
                [],
                summaryAsync.value,
                isTeacher,
                isDark,
              ),
            ),

            const SizedBox(height: 20),

            // 3. "Due soon": Max 3 assignment rows with small status dot and "See all" link
            _buildDueSoonSection(context, assignmentsAsync, isTeacher, isDark),

            const SizedBox(height: 20),

            // 4. Row of 4 quick actions as simple icon buttons with labels
            _buildQuickActions(context, isTeacher, isDark),

            const SizedBox(height: 20),

            // 5. Small attendance / progress summary using one slim progress ring
            _buildProgressSummary(
              context,
              assignmentsAsync,
              classroomsAsync,
              isTeacher,
              isDark,
            ),

            const SizedBox(height: 24),
          ],
        ],
      ),
    ),
  );
}

  // 2. Next class card implementation
  Widget _buildNextClassCard(
    BuildContext context,
    List<ClassroomItem> classrooms,
    HomeSummary? summary,
    bool isTeacher,
    bool isDark,
  ) {
    final nextClass = classrooms.isNotEmpty ? classrooms.first : null;
    final hasClass = nextClass != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? ClayTokens.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Theme.of(context).colorScheme.outlineVariant
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ClayTokens.brightBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isTeacher ? 'NEXT SESSION' : 'NEXT CLASS',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: ClayTokens.brightBlue,
                  ),
                ),
              ),
              const Spacer(),
              if (hasClass && nextClass.code?.isNotEmpty == true)
                Text(
                  'Code: ${nextClass.code}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : ClayTokens.secondaryText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasClass ? nextClass.name : (isTeacher ? 'No classes scheduled' : 'No upcoming classes today'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasClass
                ? '${nextClass.subject} · ${nextClass.schedule.isNotEmpty ? nextClass.schedule : (isTeacher ? "${nextClass.studentCount} students" : "Today, 10:00 AM")}'
                : (isTeacher ? 'Create your first classroom to begin teaching.' : 'Join your enrolled courses to stay on track.'),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : ClayTokens.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ClayTokens.brightBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: hasClass
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClassroomDetailScreen(classroom: nextClass),
                        ),
                      );
                    }
                  : () {
                      if (isTeacher) {
                        showDialog<dynamic>(
                          context: context,
                          builder: (_) => const CreateClassDialog(),
                        );
                      } else {
                        showDialog<dynamic>(
                          context: context,
                          builder: (_) => const JoinClassDialog(),
                        );
                      }
                    },
              child: Text(
                hasClass
                    ? (isTeacher ? 'Start Class' : 'Join Class')
                    : (isTeacher ? 'Create Class' : 'Join a Class'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. "Due soon" section implementation (Max 3 assignment rows)
  Widget _buildDueSoonSection(
    BuildContext context,
    AsyncValue<List<AssignmentItem>> assignmentsAsync,
    bool isTeacher,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Due soon',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateToTab(2),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: ClayTokens.brightBlue,
              ),
              child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        assignmentsAsync.when(
          data: (assignments) {
            final pending = assignments
                .where((a) => a.status == AssignmentStatus.pending)
                .take(3)
                .toList();
            final displayList = pending.isNotEmpty
                ? pending
                : assignments.take(3).toList();

            if (displayList.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Theme.of(context).colorScheme.outlineVariant
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Text(
                  'No assignments due. Enjoy the break.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : ClayTokens.secondaryText,
                  ),
                ),
              );
            }

            return Material(
              color: isDark ? ClayTokens.darkCard : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark
                      ? Theme.of(context).colorScheme.outlineVariant
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(displayList.length, (index) {
                  final item = displayList[index];
                  final isCompleted = item.status == AssignmentStatus.submitted ||
                      item.status == AssignmentStatus.graded;
                  final dotColor = isCompleted
                      ? const Color(0xFF10B981)
                      : ClayTokens.pragtiOrange;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        leading: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        minLeadingWidth: 12,
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${item.subject} · Due ${item.dueDate}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : ClayTokens.secondaryText,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                        onTap: () {
                          if (isTeacher) {
                            _showTeacherGradingDialog(context, item);
                          } else {
                            showDialog<bool>(
                              context: context,
                              builder: (_) => SubmitAssignmentDialog(assignment: item),
                            );
                          }
                        },
                      ),
                      if (index < displayList.length - 1)
                        Divider(
                          height: 1,
                          indent: 32,
                          endIndent: 14,
                          color: isDark
                              ? Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)
                              : const Color(0xFFF1F5F9),
                        ),
                    ],
                  );
                }),
              ),
            );
          },
          loading: () => Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('No assignments due. Enjoy the break.'),
          ),
        ),
      ],
    );
  }

  // 4. Quick actions row (4 simple icon buttons with labels)
  Widget _buildQuickActions(BuildContext context, bool isTeacher, bool isDark) {
    final actions = isTeacher
        ? [
            (
              icon: Icons.add_circle_outline_rounded,
              label: 'Create Class',
              onTap: () => showDialog<dynamic>(
                    context: context,
                    builder: (_) => const CreateClassDialog(),
                  ),
            ),
            (
              icon: Icons.videocam_outlined,
              label: 'Start Live Class',
              onTap: () => widget.onNavigateToTab(1),
            ),
            (
              icon: Icons.assignment_outlined,
              label: 'Assignments',
              onTap: () => widget.onNavigateToTab(2),
            ),
            (
              icon: Icons.fact_check_outlined,
              label: 'Attendance',
              onTap: () => widget.onNavigateToTab(1),
            ),
          ]
        : [
            (
              icon: Icons.add_box_outlined,
              label: 'Join Class',
              onTap: () => showDialog<dynamic>(
                    context: context,
                    builder: (_) => const JoinClassDialog(),
                  ),
            ),
            (
              icon: Icons.auto_awesome_outlined,
              label: 'Ask Mentor',
              onTap: () => context.push('/mentor'),
            ),
            (
              icon: Icons.menu_book_outlined,
              label: 'Materials',
              onTap: () => widget.onNavigateToTab(3),
            ),
            (
              icon: Icons.calendar_month_outlined,
              label: 'Schedule',
              onTap: () => widget.onNavigateToTab(4),
            ),
          ];

    return Row(
      children: actions.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: item.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Theme.of(context).colorScheme.outlineVariant
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: isDark ? Colors.white : ClayTokens.navy,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : ClayTokens.darkInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 5. Small attendance / progress summary using one slim progress ring
  Widget _buildProgressSummary(
    BuildContext context,
    AsyncValue<List<AssignmentItem>> assignmentsAsync,
    AsyncValue<List<ClassroomItem>> classroomsAsync,
    bool isTeacher,
    bool isDark,
  ) {
    final assignments = assignmentsAsync.value ?? [];
    final classrooms = classroomsAsync.value ?? [];

    final completed = assignments.where((a) => a.status != AssignmentStatus.pending).length;
    final total = assignments.length;
    final progress = total > 0 ? (completed / total) : 0.0;
    final pct = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? ClayTokens.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Theme.of(context).colorScheme.outlineVariant
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: isTeacher ? (classrooms.isNotEmpty ? 1.0 : 0.0) : (total > 0 ? progress : 0.85),
                  strokeWidth: 4,
                  backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  color: isTeacher ? const Color(0xFF8B5CF6) : ClayTokens.brightBlue,
                ),
                Text(
                  isTeacher ? '${classrooms.length}' : (total > 0 ? '$pct%' : '85%'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Academic Progress & Attendance',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  isTeacher
                      ? '${classrooms.length} active classes · ${assignments.length} assignments managed'
                      : (total > 0
                          ? '$completed of $total coursework completed · ${classrooms.length} enrolled'
                          : 'Attendance rate on track · ${classrooms.length} classes enrolled'),
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

  // Cross-entity search results renderer
  Widget _buildSearchResults(
    BuildContext context,
    AsyncValue<List<ClassroomItem>> classroomsAsync,
    AsyncValue<List<AssignmentItem>> assignmentsAsync,
    AsyncValue<List<MaterialItem>> materialsAsync,
  ) {
    final q = _searchQuery.toLowerCase();
    final matchingClasses = (classroomsAsync.value ?? [])
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.subject.toLowerCase().contains(q) ||
            (c.code ?? '').toLowerCase().contains(q))
        .toList();

    final matchingAssignments = (assignmentsAsync.value ?? [])
        .where((a) =>
            a.title.toLowerCase().contains(q) ||
            a.subject.toLowerCase().contains(q))
        .toList();

    final matchingMaterials = (materialsAsync.value ?? [])
        .where((m) =>
            m.title.toLowerCase().contains(q) ||
            m.subject.toLowerCase().contains(q))
        .toList();

    final total = matchingClasses.length + matchingAssignments.length + matchingMaterials.length;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 36, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'No results found for "$_searchQuery"',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results ($total found)',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 10),
        if (matchingClasses.isNotEmpty) ...[
          const Text('Classrooms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ClayTokens.brightBlue)),
          const SizedBox(height: 4),
          ...matchingClasses.map((c) => ListTile(
                dense: true,
                leading: const Icon(Icons.school_rounded, size: 20),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${c.subject} · Code: ${c.code}'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClassroomDetailScreen(classroom: c),
                    ),
                  );
                },
              )),
          const SizedBox(height: 8),
        ],
        if (matchingAssignments.isNotEmpty) ...[
          const Text('Assignments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ClayTokens.brightBlue)),
          const SizedBox(height: 4),
          ...matchingAssignments.map((a) => ListTile(
                dense: true,
                leading: const Icon(Icons.assignment_rounded, size: 20),
                title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${a.subject} · Due ${a.dueDate}'),
                onTap: () {
                  showDialog<bool>(
                    context: context,
                    builder: (_) => SubmitAssignmentDialog(assignment: a),
                  );
                },
              )),
          const SizedBox(height: 8),
        ],
        if (matchingMaterials.isNotEmpty) ...[
          const Text('Materials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ClayTokens.brightBlue)),
          const SizedBox(height: 4),
          ...matchingMaterials.map((m) => ListTile(
                dense: true,
                leading: const Icon(Icons.menu_book_rounded, size: 20),
                title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${m.subject} · ${m.type.name}'),
                onTap: () => widget.onNavigateToTab(3),
              )),
        ],
      ],
    );
  }
}
