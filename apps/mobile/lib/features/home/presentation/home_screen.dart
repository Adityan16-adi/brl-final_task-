import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/branding/app_branding.dart';
import 'package:mobile/core/branding/brand_widgets.dart';
import 'package:mobile/core/theme/clay_theme.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/domain/auth_repository.dart';
import 'home_providers.dart';
import 'widgets/app_drawer.dart';
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
  final GlobalKey<ScaffoldState> _wideScaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

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
    final isTeacher = user?.isTeacher == true;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ClayContainer(
                width: 64,
                height: 64,
                depth: 5,
                color: isTeacher ? ClayTokens.pragtiBlue : ClayTokens.pragtiNavy,
                borderRadius: BorderRadius.circular(22),
                child: Center(
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.name ?? 'Demo User',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.email ?? 'student@demo.com',
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              ClayBadge(
                label: user?.role.name.toUpperCase() ?? 'STUDENT',
                backgroundColor: isTeacher
                    ? const Color(0xFFF3E8FF)
                    : ClayTokens.softLavender,
                textColor: isTeacher
                    ? const Color(0xFF8B5CF6)
                    : ClayTokens.deepIndigo,
                icon: isTeacher
                    ? Icons.co_present_rounded
                    : Icons.school_rounded,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                      label: const Text('Account', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        context.push('/account');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.settings_rounded, size: 16),
                      label: const Text('Settings', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        context.push('/settings');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.help_outline_rounded, size: 16),
                      label: const Text('Help', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        context.push('/help');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClayButton(
                isFullWidth: true,
                color: Colors.redAccent.shade700,
                gradient: LinearGradient(
                  colors: [Colors.redAccent.shade400, Colors.red.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: Icons.logout_rounded,
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  ref.read(authRepositoryProvider).signOut();
                },
                child: const Text('Sign Out / Switch Account'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    Widget child;
    switch (_currentIndex) {
      case 0:
        child = OverviewView(onNavigateToTab: _onTabSelect);
        break;
      case 1:
        child = const ClassroomsView();
        break;
      case 2:
        child = const AssignmentsView();
        break;
      case 3:
        child = const MaterialsView();
        break;
      case 4:
        child = const ScheduleView();
        break;
      default:
        child = OverviewView(onNavigateToTab: _onTabSelect);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 840;

          if (isWide) {
            return Scaffold(
              key: _wideScaffoldKey,
              drawer: AppDrawer(
                currentTabIndex: _currentIndex,
                onSelectTab: _onTabSelect,
              ),
              body: Row(
                children: [
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
                          const BrandLogo(
                            size: 30,
                            useMarkOnly: true,
                            onCard: true,
                          ),
                          if (constraints.maxWidth >= 900) ...[
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  AppBranding.appName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: -0.3,
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
                              ClayButton(
                                onPressed: () => context.push('/mentor'),
                                icon: Icons.auto_awesome_rounded,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: constraints.maxWidth >= 900
                                    ? const Text('AI Mentor')
                                    : const Text('AI'),
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
                        leading: IconButton(
                          tooltip: 'Open navigation drawer',
                          icon: const Icon(Icons.menu_rounded),
                          onPressed: () => _wideScaffoldKey.currentState?.openDrawer(),
                        ),
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
                              icon: const Icon(Icons.vpn_key_rounded),
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

          // Mobile layout: Bottom NavigationBar + AppDrawer
          return Scaffold(
            key: _mobileScaffoldKey,
            drawer: AppDrawer(
              currentTabIndex: _currentIndex,
              onSelectTab: _onTabSelect,
            ),
            appBar: AppBar(
              leading: Builder(
                builder: (ctx) => IconButton(
                  tooltip: 'Open navigation drawer',
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => _mobileScaffoldKey.currentState?.openDrawer(),
                ),
              ),
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
                    icon: const Icon(Icons.vpn_key_rounded),
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
      ),
    );
  }
}
