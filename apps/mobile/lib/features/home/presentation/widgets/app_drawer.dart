import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/branding/app_branding.dart';
import '../../../../core/branding/brand_widgets.dart';
import '../../../../core/theme/clay_theme.dart';
import '../../../auth/application/auth_providers.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';
import 'create_class_dialog.dart';

/// Full navigation drawer for Pragti ("Learn · Connect · Grow").
/// Provides navigation items with count and due-soon badges, teacher actions,
/// account management links, and secure sign-out.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    this.currentTabIndex = 0,
    this.onSelectTab,
  });

  final int currentTabIndex;
  final ValueChanged<int>? onSelectTab;

  static const Color _coral = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isTeacher = user?.isTeacher == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final classrooms = ref.watch(classroomsProvider).value ?? [];
    final assignments = ref.watch(assignmentsProvider).value ?? [];
    final pendingCount = assignments
        .where((a) => a.status == AssignmentStatus.pending)
        .length;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header Profile Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(ClayTokens.radiusMedium),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/account');
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const BrandLogo(
                            size: 20,
                            useMarkOnly: true,
                            onCard: false,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            AppBranding.appName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '• ${AppBranding.tagline}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: ClayTokens.pragtiOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: NetworkImage(user.avatarUrl!),
                              backgroundColor: Colors.transparent,
                            )
                          else
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isTeacher ? ClayTokens.pragtiNavy : ClayTokens.brightBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  user?.name.isNotEmpty == true
                                      ? user!.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'User',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.email ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.white60 : ClayTokens.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? (isTeacher
                                            ? ClayTokens.pragtiNavy.withValues(alpha: 0.5)
                                            : ClayTokens.brightBlue.withValues(alpha: 0.15))
                                        : (isTeacher
                                            ? const Color(0xFFEFF6FF)
                                            : const Color(0xFFEEF4FF)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isTeacher ? 'Teacher' : 'Student',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isTeacher
                                          ? (isDark ? Colors.white70 : ClayTokens.pragtiNavy)
                                          : ClayTokens.brightBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // Scrollable Navigation Items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  children: [
                  _DrawerNavTile(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    isActive: currentTabIndex == 0,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab?.call(0);
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.school_rounded,
                    title: 'My Classes',
                    badgeText: classrooms.isNotEmpty ? '${classrooms.length}' : null,
                    badgeColor: ClayTokens.brightBlue,
                    isActive: currentTabIndex == 1,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab?.call(1);
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.assignment_rounded,
                    title: 'Assignments',
                    badgeText: pendingCount > 0 ? '$pendingCount due' : null,
                    badgeColor: ClayTokens.pragtiOrange,
                    isActive: currentTabIndex == 2,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab?.call(2);
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.checklist_rounded,
                    title: 'Study Planner & To-Do',
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/todo');
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.menu_book_rounded,
                    title: 'Learning Materials',
                    badgeText: null,
                    isActive: currentTabIndex == 3,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab?.call(3);
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.calendar_month_rounded,
                    title: 'Weekly Schedule',
                    isActive: currentTabIndex == 4,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab?.call(4);
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.people_alt_rounded,
                    title: 'Attendance Records',
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab?.call(1);
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.videocam_rounded,
                    title: 'Live Video Meetings',
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab?.call(1);
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.auto_awesome_rounded,
                    title: 'AI Mentor Tutor',
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/mentor');
                    },
                  ),

                  // Teacher specific actions
                  if (isTeacher) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'TEACHER TOOLS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                        ),
                      ),
                    ),
                    _DrawerNavTile(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Create Class',
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).pop();
                        showDialog<bool>(
                          context: context,
                          builder: (_) => const CreateClassDialog(),
                        );
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.video_call_rounded,
                      title: 'Start Live Class',
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelectTab?.call(1);
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.fact_check_rounded,
                      title: 'Grade Submissions',
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelectTab?.call(2);
                      },
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(height: 1, indent: 8, endIndent: 8),
                  ),

                  // Account / Preferences Section
                  _DrawerNavTile(
                    icon: Icons.person_outline_rounded,
                    title: 'My Profile',
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/account');
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings & Preferences',
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/settings');
                    },
                  ),
                  _DrawerNavTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help Desk & FAQ',
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/help');
                    },
                  ),
                ],
              ),
            ),
          ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // Sign Out action at bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.logout_rounded, size: 20, color: _coral),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _coral,
                    fontSize: 13.5,
                  ),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _coral,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) {
                      context.go('/welcome');
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
    this.isActive = false,
    this.badgeText,
    this.badgeColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  final bool isActive;
  final String? badgeText;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final activeBg = ClayTokens.brightBlue.withValues(alpha: isDark ? 0.2 : 0.1);
    final activeColor = ClayTokens.brightBlue;
    final inactiveColor = isDark ? Colors.white70 : ClayTokens.navy;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive ? activeBg : Colors.transparent,
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
        leading: Icon(
          icon,
          size: 20,
          color: isActive ? activeColor : (isDark ? Colors.white60 : ClayTokens.secondaryText),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? activeColor : inactiveColor,
          ),
        ),
        trailing: badgeText != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? ClayTokens.brightBlue).withValues(alpha: isDark ? 0.25 : 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText!,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: badgeColor ?? ClayTokens.brightBlue,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
