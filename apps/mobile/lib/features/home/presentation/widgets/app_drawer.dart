import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/clay_theme.dart';
import '../../../auth/application/auth_providers.dart';

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

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header Profile Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClayCard(
                depth: 3,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
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
                                horizontal: 8, vertical: 2),
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
              ),
            ),

            const Divider(height: 1),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                  _DrawerItem(
                    icon: Icons.school_rounded,
                    title: 'Classrooms',
                    selected: currentTabIndex == 1,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectTab?.call(1);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.assignment_rounded,
                    title: 'Assignments',
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
                    icon: Icons.auto_awesome_rounded,
                    title: 'AI Mentor Tutor',
                    badge: 'AI 24/7',
                    badgeColor: ClayTokens.mintDark,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/mentor');
                    },
                  ),
                  const Divider(height: 16),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings & Preferences',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/settings');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.account_circle_rounded,
                    title: 'Manage Account',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/account');
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
