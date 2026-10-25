import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/clay_theme.dart';
import '../../../auth/application/auth_providers.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';
import '../screens/classroom_detail_screen.dart';
import 'create_class_dialog.dart';
import 'join_class_dialog.dart';

class ClassroomsView extends ConsumerStatefulWidget {
  const ClassroomsView({super.key});

  @override
  ConsumerState<ClassroomsView> createState() => _ClassroomsViewState();
}

class _ClassroomsViewState extends ConsumerState<ClassroomsView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final classroomsAsync = ref.watch(classroomsProvider);
    final isTeacher = ref.watch(isTeacherProvider);
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(classroomsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Top Search & Action Bar
          Row(
            children: [
              Expanded(
                child: ClayContainer(
                  depth: 3,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search classrooms, subjects, or teachers...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: ClayTokens.secondaryText,
                      ),
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (isTeacher)
                ClayButton(
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: () async {
                    final res = await showDialog<dynamic>(
                      context: context,
                      builder: (_) => const CreateClassDialog(),
                    );
                    if (res is ClassroomItem && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClassroomDetailScreen(classroom: res),
                        ),
                      );
                    }
                  },
                  child: const Text('Create Class'),
                )
              else
                ClayButton(
                  icon: Icons.vpn_key_rounded,
                  onPressed: () async {
                    final res = await showDialog<dynamic>(
                      context: context,
                      builder: (_) => const JoinClassDialog(),
                    );
                    if (res is ClassroomItem && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClassroomDetailScreen(classroom: res),
                        ),
                      );
                    }
                  },
                  child: const Text('Join Code'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          classroomsAsync.when(
            data: (classes) {
              final filtered = classes.where((c) {
                if (_searchQuery.isEmpty) return true;
                return c.name.toLowerCase().contains(_searchQuery) ||
                    c.subject.toLowerCase().contains(_searchQuery) ||
                    c.teacher.toLowerCase().contains(_searchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        ClayContainer(
                          width: 64,
                          height: 64,
                          depth: 4,
                          borderRadius: BorderRadius.circular(20),
                          child: const Center(
                            child: Icon(
                              Icons.school_outlined,
                              size: 32,
                              color: ClayTokens.deepIndigo,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _searchQuery.isEmpty
                              ? (isTeacher
                                    ? 'No classrooms created yet'
                                    : 'No classrooms joined yet')
                              : 'No classrooms matching "$_searchQuery"',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isTeacher
                              ? 'Tap "Create Class" to set up your first virtual classroom.'
                              : 'Tap "Join Code" with an invite code from your instructor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 185,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildClassroomCard(context, item);
                    },
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: ClaySkeletonList(itemCount: 3),
            ),
            error: (err, _) =>
                Center(child: Text('Error loading classrooms: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomCard(BuildContext context, ClassroomItem item) {
    final colors = Theme.of(context).colorScheme;

    return ClayCard(
      depth: 5,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClassroomDetailScreen(classroom: item),
          ),
        );
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: ClayBadge(
                  label: item.subject,
                  backgroundColor: ClayTokens.softLavender,
                  textColor: ClayTokens.deepIndigo,
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.code != null)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: item.code!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Class code "${item.code}" copied!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: ClayContainer(
                        depth: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Code: ${item.code}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded, size: 10),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _showClassroomDetails(context, item),
                    child: const Icon(Icons.info_outline_rounded, size: 16),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: ClayTokens.softLavender,
                child: Text(
                  item.teacher
                      .split(' ')
                      .map((p) => p.isNotEmpty ? p[0] : '')
                      .take(2)
                      .join(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ClayTokens.deepIndigo,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.teacher,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.schedule,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.room_rounded,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.room,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClassroomDetails(BuildContext context, ClassroomItem item) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClayContainer(
                    width: 48,
                    height: 48,
                    depth: 4,
                    color: ClayTokens.softLavender,
                    borderRadius: BorderRadius.circular(14),
                    child: const Icon(
                      Icons.school_rounded,
                      color: ClayTokens.deepIndigo,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${item.subject} · ${item.teacher}',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClayContainer(
                depth: 3,
                padding: const EdgeInsets.all(14),
                borderRadius: BorderRadius.circular(ClayTokens.radiusMedium),
                child: Column(
                  children: [
                    _infoRow(
                      'Schedule',
                      item.schedule,
                      Icons.calendar_today_rounded,
                      colors,
                    ),
                    const Divider(height: 16),
                    _infoRow('Location', item.room, Icons.room_rounded, colors),
                    const Divider(height: 16),
                    _infoRow(
                      'Enrolled Learners',
                      '${item.studentCount} students',
                      Icons.groups_rounded,
                      colors,
                    ),
                    if (item.code != null) ...[
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.vpn_key_rounded,
                            size: 16,
                            color: ClayTokens.deepIndigo,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Class Code',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          ClayBadge(
                            label: item.code!,
                            backgroundColor: ClayTokens.softLavender,
                            textColor: ClayTokens.deepIndigo,
                            fontSize: 12,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: item.code!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Class code "${item.code}" copied!',
                                  ),
                                  backgroundColor: ClayTokens.deepIndigo,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Teacher View: Enrolled Students List
              if (ref.read(isTeacherProvider)) ...[
                const SizedBox(height: 16),
                Text(
                  'Enrolled Learners',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<ClassroomDetails>(
                  future: ref
                      .read(homeRepositoryProvider)
                      .getClassroomDetails(item.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final details = snapshot.data;
                    final students = details?.students ?? [];
                    if (students.isEmpty) {
                      return ClayContainer(
                        depth: 2,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'No students have enrolled yet. Share code "${item.code ?? ''}" with your learners.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: students.map((s) {
                        return ClayContainer(
                          margin: const EdgeInsets.only(bottom: 6),
                          depth: 2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: ClayTokens.softLavender,
                                child: Text(
                                  s.name.isNotEmpty
                                      ? s.name[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: ClayTokens.deepIndigo,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      s.email,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                'https://pragti.app/class/${item.id}',
                          ),
                        );
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Meeting preview link copied to clipboard.',
                            ),
                            backgroundColor: ClayTokens.deepIndigo,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Link'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClayButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ClassroomDetailScreen(classroom: item),
                          ),
                        );
                      },
                      icon: Icons.videocam_rounded,
                      child: const Text('Open Classroom'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(
    String label,
    String value,
    IconData icon,
    ColorScheme colors,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ClayTokens.deepIndigo),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
