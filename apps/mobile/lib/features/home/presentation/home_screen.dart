import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/branding/app_branding.dart';
import 'package:mobile/core/theme/app_theme.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/domain/auth_repository.dart';
import 'home_providers.dart';
import 'widgets/assignments_view.dart';
import 'widgets/classrooms_view.dart';
import 'widgets/create_class_dialog.dart';
import 'widgets/join_class_dialog.dart';
import 'widgets/materials_view.dart';
import 'widgets/overview_view.dart';
import 'widgets/schedule_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  static const _titles = [
    'Dashboard Overview',
    'Enrolled Classrooms',
    'Course Assignments',
    'Learning Materials',
    'Weekly Schedule',
  ];

  void _onTabSelect(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  void _cycleTheme() {
    ref.read(themeModeProvider.notifier).cycle();
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }

  String _getThemeTooltip(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Theme: System (Tap to toggle)';
      case ThemeMode.light:
        return 'Theme: Light (Tap to toggle)';
      case ThemeMode.dark:
        return 'Theme: Dark (Tap to toggle)';
    }
  }

  void _showAccountSheet(BuildContext context, AppUser? user) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 28,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user?.name ?? 'Demo User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user?.email ?? 'student@demo.com',
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (user?.isTeacher == true
                              ? AppTheme.roleTeacher
                              : AppTheme.roleStudent)
                          .withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        (user?.isTeacher == true
                                ? AppTheme.roleTeacher
                                : AppTheme.roleStudent)
                            .withAlpha(80),
                  ),
                ),
                child: Text(
                  user?.role.name.toUpperCase() ?? 'STUDENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: user?.isTeacher == true
                        ? AppTheme.roleTeacher
                        : AppTheme.roleStudent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  ref.read(authRepositoryProvider).signOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out / Switch Account'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return OverviewView(onNavigateToTab: _onTabSelect);
      case 1:
        return const ClassroomsView();
      case 2:
        return const AssignmentsView();
      case 3:
        return const MaterialsView();
      case 4:
        return const ScheduleView();
      default:
        return OverviewView(onNavigateToTab: _onTabSelect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentThemeMode = ref.watch(themeModeProvider);
    final currentUser = ref.watch(currentUserProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 640;

        if (isWideScreen) {
          return Scaffold(
            body: Row(
              children: [
                // Navigation Rail for tablet / desktop / wide screens
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onTabSelect,
                  extended: constraints.maxWidth >= 900,
                  minExtendedWidth: 200,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            color: colors.onPrimary,
                            size: 20,
                          ),
                        ),
                        if (constraints.maxWidth >= 900) ...[
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppBranding.appName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                currentUser?.name ?? 'Virtual Classroom',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Account Profile',
                              icon: const Icon(Icons.account_circle_outlined),
                              onPressed: () =>
                                  _showAccountSheet(context, currentUser),
                            ),
                            const SizedBox(height: 4),
                            IconButton(
                              tooltip: _getThemeTooltip(currentThemeMode),
                              icon: Icon(_getThemeIcon(currentThemeMode)),
                              onPressed: _cycleTheme,
                            ),
                            const SizedBox(height: 8),
                            FilledButton.tonalIcon(
                              onPressed: () => context.push('/mentor'),
                              icon: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 18,
                              ),
                              label: constraints.maxWidth >= 900
                                  ? const Text('AI Mentor')
                                  : const Text('AI'),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Overview'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.school_outlined),
                      selectedIcon: Icon(Icons.school_rounded),
                      label: Text('Classrooms'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.assignment_outlined),
                      selectedIcon: Icon(Icons.assignment_rounded),
                      label: Text('Assignments'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book_rounded),
                      label: Text('Materials'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month_rounded),
                      label: Text('Schedule'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(_titles[_currentIndex]),
                      actions: [
                        if (currentUser?.isTeacher == true)
                          IconButton(
                            tooltip: 'Create Classroom',
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            onPressed: () => showDialog<bool>(
                              context: context,
                              builder: (_) => const CreateClassDialog(),
                            ),
                          )
                        else
                          IconButton(
                            tooltip: 'Join Classroom with Code',
                            icon: const Icon(Icons.group_add_outlined),
                            onPressed: () => showDialog<bool>(
                              context: context,
                              builder: (_) => const JoinClassDialog(),
                            ),
                          ),
                        IconButton(
                          tooltip: 'AI Mentor Assistant',
                          icon: const Icon(Icons.auto_awesome_rounded),
                          onPressed: () => context.push('/mentor'),
                        ),
                        IconButton(
                          tooltip: _getThemeTooltip(currentThemeMode),
                          icon: Icon(_getThemeIcon(currentThemeMode)),
                          onPressed: _cycleTheme,
                        ),
                        IconButton(
                          tooltip: 'Account Profile',
                          icon: const Icon(Icons.account_circle_outlined),
                          onPressed: () =>
                              _showAccountSheet(context, currentUser),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    body: _buildBody(),
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile layout: Bottom NavigationBar
        return Scaffold(
          appBar: AppBar(
            title: Text(_titles[_currentIndex]),
            actions: [
              if (currentUser?.isTeacher == true)
                IconButton(
                  tooltip: 'Create Classroom',
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => const CreateClassDialog(),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Join Classroom with Code',
                  icon: const Icon(Icons.group_add_outlined),
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => const JoinClassDialog(),
                  ),
                ),
              IconButton(
                tooltip: 'AI Mentor Assistant',
                icon: const Icon(Icons.auto_awesome_rounded),
                onPressed: () => context.push('/mentor'),
              ),
              IconButton(
                tooltip: _getThemeTooltip(currentThemeMode),
                icon: Icon(_getThemeIcon(currentThemeMode)),
                onPressed: _cycleTheme,
              ),
              IconButton(
                tooltip: 'Account Profile',
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () => _showAccountSheet(context, currentUser),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: _buildBody(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelect,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Overview',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school_rounded),
                label: 'Classrooms',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment_rounded),
                label: 'Assignments',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Materials',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Schedule',
              ),
            ],
          ),
        );
      },
    );
  }
}
