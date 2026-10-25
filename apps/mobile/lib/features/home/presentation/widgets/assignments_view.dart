import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/clay_theme.dart';
import '../../../auth/application/auth_providers.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';
import 'create_assignment_dialog.dart';
import 'submit_assignment_dialog.dart';

class AssignmentsView extends ConsumerStatefulWidget {
  const AssignmentsView({super.key});

  @override
  ConsumerState<AssignmentsView> createState() => _AssignmentsViewState();
}

class _AssignmentsViewState extends ConsumerState<AssignmentsView> {
  AssignmentStatus? _filterStatus;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final isTeacher = ref.watch(isTeacherProvider);
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(assignmentsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Search & Filter header
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
                      hintText: 'Search assignments or subjects...',
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
              if (isTeacher) ...[
                const SizedBox(width: 12),
                ClayButton(
                  icon: Icons.add_task_rounded,
                  onPressed: () => showDialog<bool>(
                    context: context,
                    builder: (_) => const CreateAssignmentDialog(),
                  ),
                  child: const Text('New Task'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Tasks'),
                  selected: _filterStatus == null,
                  onSelected: (_) => setState(() => _filterStatus = null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.hourglass_top_rounded, size: 15),
                  label: const Text('Pending'),
                  selected: _filterStatus == AssignmentStatus.pending,
                  onSelected: (_) =>
                      setState(() => _filterStatus = AssignmentStatus.pending),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 15,
                  ),
                  label: const Text('Submitted'),
                  selected: _filterStatus == AssignmentStatus.submitted,
                  onSelected: (_) => setState(
                    () => _filterStatus = AssignmentStatus.submitted,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.grade_rounded, size: 15),
                  label: const Text('Graded'),
                  selected: _filterStatus == AssignmentStatus.graded,
                  onSelected: (_) =>
                      setState(() => _filterStatus = AssignmentStatus.graded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          assignmentsAsync.when(
            data: (assignments) {
              final filtered = assignments.where((a) {
                if (_filterStatus != null && a.status != _filterStatus) {
                  return false;
                }
                if (_searchQuery.isNotEmpty) {
                  final matchTitle = a.title.toLowerCase().contains(
                    _searchQuery,
                  );
                  final matchSub = a.subject.toLowerCase().contains(
                    _searchQuery,
                  );
                  if (!matchTitle && !matchSub) return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClayContainer(
                          width: 64,
                          height: 64,
                          depth: 4,
                          borderRadius: BorderRadius.circular(20),
                          child: const Center(
                            child: Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 32,
                              color: ClayTokens.deepIndigo,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _filterStatus != null || _searchQuery.isNotEmpty
                              ? 'No matching assignments found'
                              : 'All caught up! No assignments right now.',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_filterStatus != null ||
                            _searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _filterStatus = null;
                              _searchQuery = '';
                            }),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Reset filters'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;

                  if (isWide) {
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: filtered.map((item) {
                        final cardWidth = (constraints.maxWidth - 14) / 2;
                        return SizedBox(
                          width: cardWidth,
                          child: _AssignmentCard(assignment: item),
                        );
                      }).toList(),
                    );
                  }

                  return Column(
                    children: filtered
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AssignmentCard(assignment: item),
                          ),
                        )
                        .toList(),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: ClaySkeletonList(itemCount: 3),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: colors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load assignments: $err',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(assignmentsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment});

  final AssignmentItem assignment;

  Color _getStatusBg(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.pending:
        return ClayTokens.softPeach;
      case AssignmentStatus.submitted:
        return ClayTokens.softLavender;
      case AssignmentStatus.graded:
        return ClayTokens.mint;
    }
  }

  Color _getStatusText(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.pending:
        return ClayTokens.peachDark;
      case AssignmentStatus.submitted:
        return ClayTokens.deepIndigo;
      case AssignmentStatus.graded:
        return ClayTokens.mintDark;
    }
  }

  String _getStatusLabel(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.pending:
        return 'Pending';
      case AssignmentStatus.submitted:
        return 'Submitted';
      case AssignmentStatus.graded:
        return 'Graded';
    }
  }

  IconData _getStatusIcon(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.pending:
        return Icons.hourglass_top_rounded;
      case AssignmentStatus.submitted:
        return Icons.check_circle_outline_rounded;
      case AssignmentStatus.graded:
        return Icons.verified_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusBg = _getStatusBg(assignment.status);
    final statusText = _getStatusText(assignment.status);
    final statusLabel = _getStatusLabel(assignment.status);
    final isGraded = assignment.status == AssignmentStatus.graded;
    final isSubmitted = assignment.status == AssignmentStatus.submitted;

    return ClayCard(
      depth: 5,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Subject & Status Chip
          Row(
            children: [
              ClayBadge(
                label: assignment.subject,
                backgroundColor: ClayTokens.softLavender,
                textColor: ClayTokens.deepIndigo,
              ),
              const Spacer(),
              ClayBadge(
                label: statusLabel,
                icon: _getStatusIcon(assignment.status),
                backgroundColor: statusBg,
                textColor: statusText,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            assignment.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),

          // Description preview
          if (assignment.description.isNotEmpty) ...[
            Text(
              assignment.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Meta row: Due date & points
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Due: ${assignment.dueDate}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ClayContainer(
                depth: 2,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                borderRadius: BorderRadius.circular(6),
                child: Text(
                  '${assignment.points} pts',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),

          if (assignment.attachmentUrl != null &&
              assignment.attachmentUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attachment_rounded, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    assignment.attachmentName ?? assignment.attachmentUrl!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          if (isGraded && assignment.marks != null) ...[
            const SizedBox(height: 10),
            ClayContainer(
              depth: 2,
              color: ClayTokens.mint,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  const Icon(
                    Icons.grade_rounded,
                    size: 16,
                    color: ClayTokens.mintDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Score: ${assignment.marks} / ${assignment.points}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ClayTokens.mintDark,
                    ),
                  ),
                  if (assignment.feedback != null) ...[
                    const Spacer(),
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 14,
                      color: ClayTokens.mintDark,
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: isGraded
                ? OutlinedButton.icon(
                    onPressed: () => _openSubmitDialog(context),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View Submission & Feedback'),
                  )
                : isSubmitted
                ? OutlinedButton.icon(
                    onPressed: () => _openSubmitDialog(context),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('View / Resubmit Work'),
                  )
                : FilledButton.icon(
                    onPressed: () => _openSubmitDialog(context),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Submit Assignment'),
                  ),
          ),
        ],
      ),
    );
  }

  void _openSubmitDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (_) => SubmitAssignmentDialog(assignment: assignment),
    );
  }
}
