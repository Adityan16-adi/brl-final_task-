import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/branding/app_branding.dart';
import '../../../../core/branding/brand_widgets.dart';
import '../../../../core/theme/clay_theme.dart';
import '../../../auth/application/auth_providers.dart';
import '../home_providers.dart';

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

    final classroomsAsync = ref.watch(classroomsProvider);
    final assignmentsAsync = ref.watch(assignmentsProvider);

    final classrooms = classroomsAsync.value ?? [];
    final assignments = assignmentsAsync.value ?? [];
    final pendingAssignmentsCount = assignments.length;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header Profile Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(ClayTokens.radiusMedium),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/account');
                },
                child: ClayCard(
                  depth: 3,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          const SizedBox(width: 6),
                          const Text(
                            AppBranding.appName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              '• ${AppBranding.tagline}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ClayTokens.pragtiOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                      if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(user.avatarUrl!),
                          backgroundColor: Colors.transparent,
                        )
                      else
                        ClayContainer(
                          width: 50,
                          height: 50,
                          depth: 4,
                          gradient: LinearGradient(
                            colors: isTeacher
                                ? [const Color(0xFF9333EA), const Color(0xFF6B21A8)]
                                : [const Color(0xFF6356F5), const Color(0xFF473BB8)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
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
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: ClayTokens.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isTeacher
                                    ? const Color(0xFFF3E8FF)
                                    : const Color(0xFFEDEAF8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isTeacher ? 'Instructor' : 'Student',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isTeacher
                                      ? const Color(0xFF7E22CE)
                                      : ClayTokens.deepIndigo,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

            const Divider(height: 1),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 2),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard Overview',
                    selected: currentTabIndex == 0,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab?.call(0);
                    },
                  ),

                  // My Classes Expandable Section
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: Icon(
                        Icons.school_rounded,
                        size: 20,
                        color: currentTabIndex == 1 ? ClayTokens.deepIndigo : null,
                      ),
                      title: const Text(
                        'My Classes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: ClayTokens.deepIndigo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${classrooms.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: ClayTokens.deepIndigo,
                          ),
                        ),
                      ),
                      children: [
                        ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.only(left: 36, right: 16),
                          leading: const Icon(Icons.grid_view_rounded, size: 16),
                          title: const Text('View All Classrooms', style: TextStyle(fontSize: 13)),
                          onTap: () {
                            Navigator.of(context).pop();
                            onSelectTab?.call(1);
                          },
                        ),
                        if (classrooms.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 36),
                            child: Text(
                              'No enrolled classes',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          )
                        else
                          ...classrooms.map(
                            (c) => ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.only(left: 36, right: 16),
                              leading: const Icon(Icons.bookmark_border_rounded, size: 16),
                              title: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                c.subject,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                context.push('/classroom/${c.id}', extra: c);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  _DrawerItem(
                    icon: Icons.assignment_rounded,
                    title: 'Assignments',
                    badge: pendingAssignmentsCount > 0 ? '$pendingAssignmentsCount' : null,
                    badgeColor: isTeacher ? ClayTokens.deepIndigo : const Color(0xFFEAB308),
                    selected: currentTabIndex == 2,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab?.call(2);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.checklist_rounded,
                    title: 'Study Planner & To-Do',
                    badge: 'Urgent',
                    badgeColor: ClayTokens.deepIndigo,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/todo');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.menu_book_rounded,
                    title: 'Learning Materials',
                    selected: currentTabIndex == 3,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab?.call(3);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.calendar_month_rounded,
                    title: 'Weekly Schedule',
                    selected: currentTabIndex == 4,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab?.call(4);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.fact_check_rounded,
                    title: 'Attendance Records',
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab?.call(1); // Navigates to classrooms for attendance
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.video_camera_front_rounded,
                    title: 'Live Video Meetings',
                    badge: 'LiveKit',
                    badgeColor: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab?.call(1); // Navigates to classrooms to join meeting
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.auto_awesome_rounded,
                    title: 'AI Mentor Tutor',
                    badge: 'AI 24/7',
                    badgeColor: ClayTokens.mintDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/mentor');
                    },
                  ),
                  const Divider(height: 6),
                  _DrawerItem(
                    icon: Icons.account_circle_rounded,
                    title: 'Manage Account',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/account');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings & Preferences',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/settings');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help Desk & FAQ',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/help');
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Logout Footer
            ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              leading: const Icon(Icons.logout_rounded, color: _coral),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _coral,
                  fontSize: 14,
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
                    context.go('/login');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.badge,
    this.badgeColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      selected: selected,
      selectedTileColor: ClayTokens.deepIndigo.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(
        icon,
        size: 20,
        color: selected ? ClayTokens.deepIndigo : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? ClayTokens.deepIndigo : null,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? ClayTokens.deepIndigo).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: badgeColor ?? ClayTokens.deepIndigo,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
