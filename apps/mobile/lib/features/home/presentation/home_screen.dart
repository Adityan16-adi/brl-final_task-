
import 'package:flutter/material.dart';
import 'package:mobile/core/branding/app_branding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _sections = [
    ('Overview', Icons.dashboard_outlined),
    ('My classrooms', Icons.groups_outlined),
    ('Assignments', Icons.assignment_outlined),
    ('Learning materials', Icons.menu_book_outlined),
    ('Profile & settings', Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _sections[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(selected.$1),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _message(
              'Notifications will be added in a later phase.',
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _message(
                'Classroom creation will be connected later.',
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New classroom'),
            )
          : null,
      body: _selectedIndex == 0
          ? _overview(context)
          : _placeholder(context, selected.$1),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Drawer(
      width: 280,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 24),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppBranding.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          AppBranding.tagline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 16, 8),
              child: Text('LEARNING'),
            ),
            for (var i = 0; i < 4; i++)
              _drawerItem(
                context: context,
                index: i,
                icon: _sections[i].$2,
                label: _sections[i].$1,
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 16, 8),
              child: Text('ACCOUNT'),
            ),
            _drawerItem(
              context: context,
              index: 4,
              icon: _sections[4].$2,
              label: _sections[4].$1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: isSelected ? colors.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() => _selectedIndex = index);
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? colors.onSecondaryContainer
                      : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? colors.onSecondaryContainer : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _overview(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Text(
          'Your learning space',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A place to learn, collaborate, and stay on track.',
          style: textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: colors.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.onPrimaryContainer,
                  size: 30,
                ),
                const SizedBox(height: 16),
                Text(
                  'Make every learning day count.',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your classes, coursework, and resources will have one home.',
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _message(
                    'Classroom discovery will be added later.',
                  ),
                  child: const Text('Explore classrooms'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Your workspace',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 700 ? 3 : 2;
            final width =
                (constraints.maxWidth - (columns - 1) * 12) / columns;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _workspaceCard(
                  width,
                  context,
                  'Classrooms',
                  'Your learning communities',
                  Icons.groups_rounded,
                  () => _select(1),
                ),
                _workspaceCard(
                  width,
                  context,
                  'Assignments',
                  'Tasks and coursework',
                  Icons.assignment_rounded,
                  () => _select(2),
                ),
                _workspaceCard(
                  width,
                  context,
                  'Materials',
                  'Notes and resources',
                  Icons.menu_book_rounded,
                  () => _select(3),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Text(
          'Coming up',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(
              Icons.event_available_rounded,
              color: colors.primary,
              size: 30,
            ),
            title: const Text('Your schedule starts here'),
            subtitle: const Text(
              'Classes, deadlines, and activities will appear here once connected.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _workspaceCard(
    double width,
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 30, color: colors.primary),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 5),
                Text(description),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded, size: 48),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'This section is part of the app shell. Its data and actions will be added in later phases.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _select(0),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to overview'),
            ),
          ],
        ),
      ),
    );
  }

  void _select(int index) {
    setState(() => _selectedIndex = index);
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
