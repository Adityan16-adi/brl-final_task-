import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Formats raw date strings into friendly strings: "Sun, 1 Nov" or "Due tomorrow" (never raw ISO).
String formatFriendlyDate(String rawDate) {
  if (rawDate.trim().isEmpty) return '';
  final lower = rawDate.toLowerCase();
  if (lower.contains('today') || lower.contains('tomorrow') || lower.contains('yesterday')) {
    return rawDate;
  }
  final dt = DateTime.tryParse(rawDate.trim());
  if (dt != null) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diffDays = target.difference(today).inDays;
    if (diffDays == 0) return 'Due today';
    if (diffDays == 1) return 'Due tomorrow';
    if (diffDays == -1) return 'Due yesterday';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekday = weekdays[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$weekday, ${dt.day} $month';
  }
  return rawDate;
}

/// Bento Grid Dashboard Overview for Pragti ("Learn · Connect · Grow").
/// Provides greeting, next-class hero card, two-column bento row,
/// 8 quick-action tiles in 2 rows, "My classes", "Upcoming schedule",
/// "Due soon" list, "Recent materials", and slim AI Mentor banner.
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
    return '$weekday, ${now.day} $month';
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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Review Submissions',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${assignment.title} • ${assignment.subject}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.people_outline_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '3 student submissions ready for grading',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  widget.onNavigateToTab(2);
                },
                icon: const Icon(Icons.rate_review_rounded, size: 18),
                label: const Text('Open Assignments Tab'),
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

    final classroomsAsync = ref.watch(classroomsProvider);
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final materialsAsync = ref.watch(materialsProvider);
    final scheduleAsync = ref.watch(scheduleProvider);
    final summaryAsync = ref.watch(homeSummaryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(classroomsProvider);
        ref.invalidate(assignmentsProvider);
        ref.invalidate(materialsProvider);
        ref.invalidate(scheduleProvider);
        ref.invalidate(homeSummaryProvider);
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              children: [
                // 1. Clean Top Greeting (No large empty gap, avatar is in AppBar)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Dashboard Overview',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: ClayTokens.brightBlue,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '• ${_getFormattedDate()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getGreeting(currentUser?.name),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: isDark ? Colors.white : ClayTokens.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                        size: 22,
                      ),
                      tooltip: 'Search courses & materials',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _isSearchOpen = !_isSearchOpen;
                          if (!_isSearchOpen) {
                            _searchQuery = '';
                            _searchController.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),

                // Search field when open
                if (_isSearchOpen) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search classes, assignments, materials...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (q) => setState(() => _searchQuery = q.trim()),
                  ),
                ],

                // Demo Data Badge if in offline demo mode
                if (currentUser?.isDemo == true) ...[
                  const SizedBox(height: 8),
                  const DemoDataBadge(message: 'DEMO DATA', compact: true),
                ],

                const SizedBox(height: 12),

                // Active search results
                if (_searchQuery.isNotEmpty) ...[
                  _buildSearchResults(
                    context,
                    classroomsAsync,
                    assignmentsAsync,
                    materialsAsync,
                  ),
                ] else ...[
                  // 2. Hero "Next class" Card
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

                  const SizedBox(height: 14),

                  // 3. Two-Column Bento Row: Due Soon (Left) & Attendance (Right)
                  _buildBentoRow(
                    context,
                    assignmentsAsync,
                    classroomsAsync,
                    isTeacher,
                    isDark,
                  ),

                  const SizedBox(height: 18),

                  // 4. Quick Action Tiles (8 tiles in 2 rows with 0.97 scale press feedback)
                  _buildQuickActions(context, isTeacher, isDark),

                  const SizedBox(height: 20),

                  // 5. "My classes" (max 3, "See all")
                  _buildMyClassesSection(
                    context,
                    classroomsAsync,
                    isTeacher,
                    isDark,
                  ),

                  const SizedBox(height: 20),

                  // 6. "Upcoming schedule" (max 2, "See all")
                  _buildUpcomingScheduleSection(
                    context,
                    scheduleAsync,
                    isTeacher,
                    isDark,
                  ),

                  const SizedBox(height: 20),

                  // 7. "Due soon" List (Max 3 rows + "See all" link)
                  _buildDueSoonSection(
                    context,
                    assignmentsAsync,
                    isTeacher,
                    isDark,
                  ),

                  const SizedBox(height: 20),

                  // 8. "Recent materials" (max 2, "See all")
                  _buildRecentMaterialsSection(
                    context,
                    materialsAsync,
                    isDark,
                  ),

                  const SizedBox(height: 20),

                  // 9. Slim "Ask AI Mentor" row
                  _buildSlimMentorBanner(context, isDark),

                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard(bool isDark) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ClayTokens.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClaySkeleton(width: 80, height: 16, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 14),
          ClaySkeleton(width: 180, height: 20, borderRadius: BorderRadius.circular(4)),
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
    final hasClasses = classrooms.isNotEmpty;
    final nextClass = hasClasses ? classrooms.first : null;
    final title = nextClass?.name ?? summary?.nextClassTitle ?? 'Virtual Classroom';
    final rawTime = nextClass?.schedule.isNotEmpty == true
        ? nextClass!.schedule
        : (summary?.nextClassTime ?? 'Scheduled Lecture');
    final formattedTime = formatFriendlyDate(rawTime);
    final subject = nextClass?.subject ?? 'Pragti Coursework';
    final room = nextClass?.room.isNotEmpty == true ? nextClass!.room : 'Virtual Hall';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ClayTokens.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isTeacher
                        ? ClayTokens.pragtiOrange.withValues(alpha: isDark ? 0.2 : 0.1)
                        : ClayTokens.brightBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isTeacher ? 'Instructor Dashboard Active' : 'NEXT CLASS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: isTeacher ? ClayTokens.pragtiOrange : ClayTokens.brightBlue,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Live now',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : ClayTokens.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$subject • $room',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 15,
                color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  formattedTime,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : ClayTokens.navy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ClayTokens.brightBlue,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (hasClasses) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClassroomDetailScreen(classroom: nextClass!),
                      ),
                    );
                  } else {
                    widget.onNavigateToTab(1);
                  }
                },
                icon: Icon(hasClasses ? Icons.login_rounded : Icons.add_rounded, size: 14),
                label: Text(
                  hasClasses ? 'Join' : 'Find Class',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
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
    final count = pendingAssignments.length;
    final nearestDue = pendingAssignments.isNotEmpty
        ? formatFriendlyDate(pendingAssignments.first.dueDate)
        : (assignments.isNotEmpty ? formatFriendlyDate(assignments.first.dueDate) : 'No deadlines');

    final pct = count > 0 ? (100 - (count * 15)).clamp(70, 96) : 95;

    return Row(
      children: [
        // Left Bento: Due Soon
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? ClayTokens.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
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
                Text(
                  'Due soon',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : ClayTokens.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nearestDue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ClayTokens.pragtiOrange,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Right Bento: Attendance Progress
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? ClayTokens.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
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
                        isTeacher ? 'Attendance' : 'Academic Progress & Attendance',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isTeacher ? '${classrooms.length * 18}' : '$pct%',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : ClayTokens.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isTeacher ? 'Present today' : 'Overall rate',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: isTeacher ? 0.88 : (pct / 100),
                        strokeWidth: 3.5,
                        backgroundColor: ClayTokens.brightBlue.withValues(alpha: isDark ? 0.15 : 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(ClayTokens.brightBlue),
                      ),
                      const Icon(Icons.check_rounded, size: 16, color: ClayTokens.brightBlue),
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

  // 4. Quick Action Tiles (8 tiles in 2 rows with 0.97 scale press feedback)
  Widget _buildQuickActions(BuildContext context, bool isTeacher, bool isDark) {
    final List<({IconData icon, String label, VoidCallback onTap})> row1;
    final List<({IconData icon, String label, VoidCallback onTap})> row2;

    if (isTeacher) {
      row1 = [
        (
          icon: Icons.add_circle_outline_rounded,
          label: 'Create Class',
          onTap: () {
            HapticFeedback.lightImpact();
            showDialog<dynamic>(
              context: context,
              builder: (_) => const CreateClassDialog(),
            );
          },
        ),
        (
          icon: Icons.video_call_rounded,
          label: 'Start Live Class',
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onNavigateToTab(1);
          },
        ),
        (
          icon: Icons.assignment_rounded,
          label: 'Assignments',
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onNavigateToTab(2);
          },
        ),
        (
          icon: Icons.people_alt_rounded,
          label: 'Attendance',
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onNavigateToTab(1);
          },
        ),
      ];
      row2 = [
        (
          icon: Icons.folder_open_rounded,
          label: 'Materials',
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onNavigateToTab(3);
          },
        ),
        (
          icon: Icons.campaign_rounded,
          label: 'Announce',
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onNavigateToTab(1);
          },
        ),
        (
          icon: Icons.fact_check_rounded,
          label: 'Grade',
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onNavigateToTab(2);
          },
        ),
        (
          icon: Icons.calendar_month_rounded,
          label: 'Schedule',
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onNavigateToTab(4);
          },
        ),
      ];
    } else {
      row1 = [
        (
          icon: Icons.vpn_key_rounded,
          label: 'Join Class',
          onTap: () {
            HapticFeedback.lightImpact();
            showDialog<dynamic>(
              context: context,
              builder: (_) => const JoinClassDialog(),
            );
          },
        ),
        (
          icon: Icons.auto_awesome_rounded,
          label: 'Ask Mentor',
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/mentor');
          },
        ),
        (
          icon: Icons.folder_open_rounded,
          label: 'Materials',
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onNavigateToTab(3);
          },
        ),
        (
          icon: Icons.calendar_month_rounded,
          label: 'Schedule',
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onNavigateToTab(4);
          },
        ),
      ];
      row2 = [
        (
          icon: Icons.assignment_rounded,
          label: 'Assignments',
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onNavigateToTab(2);
          },
        ),
        (
          icon: Icons.checklist_rounded,
          label: 'Planner',
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/todo');
          },
        ),
        (
          icon: Icons.people_alt_rounded,
          label: 'Attendance',
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onNavigateToTab(1);
          },
        ),
        (
          icon: Icons.videocam_rounded,
          label: 'Live Class',
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onNavigateToTab(1);
          },
        ),
      ];
    }

    return Column(
      children: [
        Row(
          children: row1.map((item) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _QuickActionTile(
                  icon: item.icon,
                  label: item.label,
                  onTap: item.onTap,
                  isDark: isDark,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: row2.map((item) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _QuickActionTile(
                  icon: item.icon,
                  label: item.label,
                  onTap: item.onTap,
                  isDark: isDark,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 5. "My classes" Section (Max 3, "See all")
  Widget _buildMyClassesSection(
    BuildContext context,
    AsyncValue<List<ClassroomItem>> classroomsAsync,
    bool isTeacher,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'My classes',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : ClayTokens.navy,
                ),
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateToTab(1),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: ClayTokens.brightBlue,
              ),
              child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        classroomsAsync.when(
          data: (classrooms) {
            final displayList = classrooms.take(3).toList();
            if (displayList.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
                  ),
                ),
                child: Text(
                  'No enrolled classes yet. Join or create a class to get started.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                  ),
                ),
              );
            }

            return Column(
              children: displayList.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClassroomDetailScreen(classroom: c),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? ClayTokens.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: ClayTokens.brightBlue.withValues(alpha: isDark ? 0.18 : 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.school_rounded, size: 18, color: ClayTokens.brightBlue),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : ClayTokens.navy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${c.subject} • ${c.room.isNotEmpty ? c.room : "Virtual Room"}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => Container(
            height: 60,
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
            child: const Text('No classes enrolled.'),
          ),
        ),
      ],
    );
  }

  // 6. "Upcoming schedule" Section (Max 2, "See all")
  Widget _buildUpcomingScheduleSection(
    BuildContext context,
    AsyncValue<List<ScheduleItem>> scheduleAsync,
    bool isTeacher,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Upcoming schedule',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : ClayTokens.navy,
                ),
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateToTab(4),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: ClayTokens.brightBlue,
              ),
              child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        scheduleAsync.when(
          data: (schedule) {
            final displayList = schedule.take(2).toList();
            if (displayList.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
                  ),
                ),
                child: Text(
                  'No upcoming sessions on your schedule.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                  ),
                ),
              );
            }

            return Column(
              children: displayList.map((item) {
                final isDeadline = item.type.toLowerCase() == 'deadline';
                final badgeColor = isDeadline ? ClayTokens.pragtiOrange : ClayTokens.brightBlue;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => widget.onNavigateToTab(4),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? ClayTokens.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: isDark ? 0.18 : 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isDeadline ? Icons.timer_outlined : Icons.menu_book_rounded,
                              size: 18,
                              color: badgeColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : ClayTokens.navy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.subject} • ${formatFriendlyDate(item.time)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => Container(
            height: 60,
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
            child: const Text('No schedule sessions found.'),
          ),
        ),
      ],
    );
  }

  // 7. "Due soon" List (Max 3 rows + "See all" link)
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
            Expanded(
              child: Text(
                'Due soon',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : ClayTokens.navy,
                ),
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateToTab(2),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: ClayTokens.brightBlue,
              ),
              child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
                  ),
                ),
                child: Text(
                  'No assignments due. Enjoy the break.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                  ),
                ),
              );
            }

            return Column(
              children: displayList.map((item) {
                final isCompleted = item.status == AssignmentStatus.submitted ||
                    item.status == AssignmentStatus.graded;
                final dotColor = isCompleted
                    ? const Color(0xFF10B981)
                    : ClayTokens.pragtiOrange;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
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
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? ClayTokens.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : ClayTokens.navy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.subject} • Due ${formatFriendlyDate(item.dueDate)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => Container(
            height: 60,
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

  // 8. "Recent materials" Section (Max 2, "See all")
  Widget _buildRecentMaterialsSection(
    BuildContext context,
    AsyncValue<List<MaterialItem>> materialsAsync,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent materials',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : ClayTokens.navy,
                ),
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateToTab(3),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: ClayTokens.brightBlue,
              ),
              child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        materialsAsync.when(
          data: (materials) {
            final displayList = materials.take(2).toList();
            if (displayList.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
                  ),
                ),
                child: Text(
                  'No study materials uploaded yet.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                  ),
                ),
              );
            }

            return Column(
              children: displayList.map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => widget.onNavigateToTab(3),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? ClayTokens.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: ClayTokens.brightBlue.withValues(alpha: isDark ? 0.18 : 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.menu_book_rounded, size: 18, color: ClayTokens.brightBlue),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : ClayTokens.navy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${m.subject} • ${m.type.name.toUpperCase()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => Container(
            height: 60,
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
            child: const Text('No materials found.'),
          ),
        ),
      ],
    );
  }

  // 9. Slim "Ask AI Mentor" row
  Widget _buildSlimMentorBanner(BuildContext context, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/mentor');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? ClayTokens.darkCard : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? ClayTokens.darkBorder : const Color(0xFFBFDBFE),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ClayTokens.brightBlue.withValues(alpha: isDark ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: ClayTokens.brightBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask Pragti AI Mentor',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : ClayTokens.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Instant help with study concepts, summaries & quiz prep',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ClayTokens.brightBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Ask',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
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
                subtitle: Text('${c.subject} • Code: ${c.code}'),
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
                subtitle: Text('${a.subject} • Due ${formatFriendlyDate(a.dueDate)}'),
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
                subtitle: Text('${m.subject} • ${m.type.name}'),
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
        borderRadius: BorderRadius.circular(14),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: widget.isDark ? ClayTokens.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDark ? 0.25 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: ClayTokens.brightBlue.withValues(alpha: widget.isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: ClayTokens.brightBlue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
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
