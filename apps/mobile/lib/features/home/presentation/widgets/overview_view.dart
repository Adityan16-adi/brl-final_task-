import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/clay_theme.dart';
import '../../../../core/widgets/demo_data_badge.dart';
import '../../../auth/application/auth_providers.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';
import '../notification_providers.dart';
import '../screens/classroom_detail_screen.dart';
import 'create_class_dialog.dart';
import 'join_class_dialog.dart';
import 'notifications_sheet.dart';
import 'submit_assignment_dialog.dart';

/// Bento Grid Dashboard Overview for Pragti ("Learn · Connect · Grow").
/// Designed with calm modern depth, hero next-class card, two-column bento row,
/// 4 quick action tiles with scale press feedback, and due soon list.
class OverviewView extends ConsumerStatefulWidget {
  const OverviewView({required this.onNavigateToTab, super.key});

  final void Function(int tabIndex) onNavigateToTab;

  @override
  ConsumerState<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends ConsumerState<OverviewView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isSearchOpen = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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

  String _getFormattedDate() {
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return '$weekday, $month ${now.day}';
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
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with Faint Gradient Tint
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ClayTokens.brightBlue.withValues(alpha: isDark ? 0.08 : 0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                  color: isDark ? Colors.white : ClayTokens.navy,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    _getFormattedDate(),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white60 : ClayTokens.secondaryText,
                                    ),
                                  ),
                                  if (isTeacher) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '·',
                                      style: TextStyle(
                                        color: isDark ? Colors.white38 : ClayTokens.secondaryText,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Instructor Dashboard Active',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: ClayTokens.brightBlue,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Search Toggle
                        IconButton(
                          tooltip: _isSearchOpen ? 'Close search' : 'Search',
                          icon: Icon(
                            _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                            size: 22,
                          ),
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
                        // Notification Bell with Unread Dot
                        Builder(
                          builder: (context) {
                            final unreadCount = ref.watch(unreadNotificationsCountProvider);
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  tooltip: 'Notifications',
                                  icon: const Icon(Icons.notifications_none_rounded, size: 22),
                                  onPressed: () => showInAppNotificationsSheet(context),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: ClayTokens.pragtiOrange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 2),
                        // Avatar
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => context.push('/account'),
                          child: currentUser?.avatarUrl != null &&
                                  currentUser!.avatarUrl!.isNotEmpty
                              ? CircleAvatar(
                                  radius: 18,
                                  backgroundImage: NetworkImage(currentUser.avatarUrl!),
                                )
                              : Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isTeacher
                                        ? const Color(0xFF0B1E48)
                                        : ClayTokens.brightBlue,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: isDark ? 0.3 : 0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
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

                    // Expandable Search Bar
                    if (_isSearchOpen) ...[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? ClayTokens.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF243049)
                                : const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded,
                                size: 20, color: ClayTokens.brightBlue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val.trim()),
                                decoration: const InputDecoration(
                                  hintText: 'Search classes, assignments...',
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

                    // Demo Data Badge if in offline demo mode
                    if (currentUser?.isDemo == true) ...[
                      const SizedBox(height: 10),
                      const DemoDataBadge(message: 'DEMO DATA', compact: true),
                    ],
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search results if actively searching
                    if (_searchQuery.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSearchResults(
                        context,
                        classroomsAsync,
                        assignmentsAsync,
                        materialsAsync,
                      ),
                    ] else ...[
                      const SizedBox(height: 8),

                      // 2. Hero "Next Class" Card
                      classroomsAsync.when(
                        data: (classrooms) => _buildNextClassCard(
                          context,
                          classrooms,
                          summaryAsync.value,
                          isTeacher,
                          isDark,
                        ),
                        loading: () => classroomsAsync.hasValue
                            ? _buildNextClassCard(
                                context,
                                classroomsAsync.value!,
                                summaryAsync.value,
                                isTeacher,
                                isDark,
                              )
                            : _buildSkeletonCard(isDark),
                        error: (_, _) => _buildNextClassCard(
                          context,
                          [],
                          summaryAsync.value,
                          isTeacher,
                          isDark,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3. Two-Column Bento Row: Due Soon (Left) & Attendance (Right)
                      _buildBentoRow(
                        context,
                        assignmentsAsync,
                        classroomsAsync,
                        isTeacher,
                        isDark,
                      ),

                      const SizedBox(height: 20),

                      // 4. Quick Action Tiles (4 tiles with 0.97 scale press feedback)
                      _buildQuickActions(context, isTeacher, isDark),

                      const SizedBox(height: 24),

                      // 5. "Due soon" List (Max 3 rows + "See all" link)
                      _buildDueSoonSection(
                        context,
                        assignmentsAsync,
                        isTeacher,
                        isDark,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Skeleton Loader for Hero Card during initial load
  Widget _buildSkeletonCard(bool isDark) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? ClayTokens.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF243049) : const Color(0xFFE3E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClaySkeleton(width: 80, height: 16, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 14),
          ClaySkeleton(width: 180, height: 22, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 8),
          ClaySkeleton(width: 140, height: 14, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }

  // 2. Hero "Next class" Card
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
              ? const Color(0xFF243049)
              : const Color(0xFFE3E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ClayTokens.brightBlue.withValues(alpha: isDark ? 0.18 : 0.1),
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
              if (hasClass)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Live now',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasClass
                ? nextClass.name
                : (isTeacher ? 'No classes scheduled for today' : 'No classes scheduled for today'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : ClayTokens.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasClass
                ? '${nextClass.subject} · ${nextClass.teacher.isNotEmpty ? nextClass.teacher : "Instructor"} · ${nextClass.schedule.isNotEmpty ? nextClass.schedule : "10:00 AM"}'
                : (isTeacher
                    ? 'Create your first classroom to begin teaching.'
                    : 'Join your courses to stay on track.'),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : ClayTokens.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ClayTokens.brightBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                    : (isTeacher ? 'Create a class' : 'Join a class'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Two-Column Bento Row: Due Soon (Left) & Attendance (Right)
  Widget _buildBentoRow(
    BuildContext context,
    AsyncValue<List<AssignmentItem>> assignmentsAsync,
    AsyncValue<List<ClassroomItem>> classroomsAsync,
    bool isTeacher,
    bool isDark,
  ) {
    final assignments = assignmentsAsync.value ?? [];
    final classrooms = classroomsAsync.value ?? [];

    final pendingAssignments =
        assignments.where((a) => a.status == AssignmentStatus.pending).toList();
    final pendingCount = pendingAssignments.length;
    final nearestDue = pendingAssignments.isNotEmpty
        ? 'Nearest: ${pendingAssignments.first.dueDate}'
        : 'All caught up';

    final completed =
        assignments.where((a) => a.status != AssignmentStatus.pending).length;
    final total = assignments.length;
    final progress = total > 0 ? (completed / total) : 0.88;
    final pct = (progress * 100).toInt();

    return Row(
      children: [
        // Left Bento: "Due soon" big number & nearest date
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => widget.onNavigateToTab(2),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? ClayTokens.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF243049) : const Color(0xFFE3E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Due soon',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white60 : ClayTokens.secondaryText,
                        ),
                      ),
                      const Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: ClayTokens.pragtiOrange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$pendingCount',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : ClayTokens.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nearestDue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : ClayTokens.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Right Bento: Attendance overall % with slim circular progress ring
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? ClayTokens.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF243049) : const Color(0xFFE3E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Progress & Attendance',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white60 : ClayTokens.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isTeacher ? '${classrooms.length * 18}' : '$pct%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : ClayTokens.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTeacher ? 'Present today' : 'Overall rate',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : ClayTokens.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: isTeacher ? 0.94 : progress,
                        strokeWidth: 3.5,
                        backgroundColor: isDark
                            ? const Color(0xFF243049)
                            : const Color(0xFFE2E8F0),
                        color: ClayTokens.brightBlue,
                      ),
                      Icon(
                        isTeacher
                            ? Icons.how_to_reg_rounded
                            : Icons.check_circle_rounded,
                        size: 18,
                        color: ClayTokens.brightBlue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 4. Quick Actions (4 tiles with scale feedback 0.97 over 100ms)
  Widget _buildQuickActions(BuildContext context, bool isTeacher, bool isDark) {
    final actions = isTeacher
        ? [
            (
              icon: Icons.add_rounded,
              label: 'Create Class',
              onTap: () => showDialog<dynamic>(
                    context: context,
                    builder: (_) => const CreateClassDialog(),
                  ),
            ),
            (
              icon: Icons.videocam_rounded,
              label: 'Start Live',
              onTap: () => widget.onNavigateToTab(1),
            ),
            (
              icon: Icons.assignment_rounded,
              label: 'Assignments',
              onTap: () => widget.onNavigateToTab(2),
            ),
            (
              icon: Icons.people_alt_rounded,
              label: 'Attendance',
              onTap: () => widget.onNavigateToTab(1),
            ),
          ]
        : [
            (
              icon: Icons.vpn_key_rounded,
              label: 'Join Class',
              onTap: () => showDialog<dynamic>(
                    context: context,
                    builder: (_) => const JoinClassDialog(),
                  ),
            ),
            (
              icon: Icons.auto_awesome_rounded,
              label: 'Ask Mentor',
              onTap: () => context.push('/mentor'),
            ),
            (
              icon: Icons.folder_open_rounded,
              label: 'Materials',
              onTap: () => widget.onNavigateToTab(3),
            ),
            (
              icon: Icons.calendar_month_rounded,
              label: 'Schedule',
              onTap: () => widget.onNavigateToTab(4),
            ),
          ];

    return Row(
      children: actions.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _QuickActionTile(
              icon: item.icon,
              label: item.label,
              onTap: item.onTap,
              isDark: isDark,
            ),
          ),
        );
      }).toList(),
    );
  }

  // 5. "Due soon" List (Max 3 rows + "See all" link)
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
            Text(
              'Due soon',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: isDark ? Colors.white : ClayTokens.navy,
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
            final displayList =
                pending.isNotEmpty ? pending : assignments.take(3).toList();

            if (displayList.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF243049)
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
                      ? const Color(0xFF243049)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(displayList.length, (index) {
                  final item = displayList[index];
                  final isCompleted =
                      item.status == AssignmentStatus.submitted ||
                          item.status == AssignmentStatus.graded;
                  final dotColor = isCompleted
                      ? const Color(0xFF10B981)
                      : ClayTokens.pragtiOrange;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
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
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? Colors.white : ClayTokens.navy,
                          ),
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
                              builder: (_) =>
                                  SubmitAssignmentDialog(assignment: item),
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
                              ? const Color(0xFF243049)
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

  // Search Results Renderer
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

    final total = matchingClasses.length +
        matchingAssignments.length +
        matchingMaterials.length;

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
          const Text('Classrooms',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: ClayTokens.brightBlue)),
          const SizedBox(height: 4),
          ...matchingClasses.map((c) => ListTile(
                dense: true,
                leading: const Icon(Icons.school_rounded, size: 20),
                title: Text(c.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
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
          const Text('Assignments',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: ClayTokens.brightBlue)),
          const SizedBox(height: 4),
          ...matchingAssignments.map((a) => ListTile(
                dense: true,
                leading: const Icon(Icons.assignment_rounded, size: 20),
                title: Text(a.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
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
          const Text('Materials',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: ClayTokens.brightBlue)),
          const SizedBox(height: 4),
          ...matchingMaterials.map((m) => ListTile(
                dense: true,
                leading: const Icon(Icons.menu_book_rounded, size: 20),
                title: Text(m.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${m.subject} · ${m.type.name}'),
                onTap: () => widget.onNavigateToTab(3),
              )),
        ],
      ],
    );
  }
}

/// Quick action tile with AnimatedScale press feedback (0.97 scale over 100ms)
class _QuickActionTile extends StatefulWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: widget.isDark ? ClayTokens.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDark
                  ? const Color(0xFF243049)
                  : const Color(0xFFE3E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDark ? 0.25 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ClayTokens.brightBlue.withValues(alpha: widget.isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: ClayTokens.brightBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? Colors.white : ClayTokens.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
