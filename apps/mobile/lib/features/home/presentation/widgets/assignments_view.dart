import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/home_repository.dart';
import '../home_providers.dart';
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
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(assignmentsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Search & Filter header
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search assignments or subjects...',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
            onChanged: (val) =>
                setState(() => _searchQuery = val.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterStatus == null,
                  onSelected: (_) => setState(() => _filterStatus = null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(
                    Icons.pending_actions_rounded,
                    size: 16,
                    color: _filterStatus == AssignmentStatus.pending
                        ? colors.onPrimary
                        : Colors.amber.shade700,
                  ),
                  label: const Text('Pending'),
                  selected: _filterStatus == AssignmentStatus.pending,
                  onSelected: (_) =>
                      setState(() => _filterStatus = AssignmentStatus.pending),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: _filterStatus == AssignmentStatus.submitted
                        ? colors.onPrimary
                        : Colors.blue.shade700,
                  ),
                  label: const Text('Submitted'),
                  selected: _filterStatus == AssignmentStatus.submitted,
                  onSelected: (_) => setState(
                    () => _filterStatus = AssignmentStatus.submitted,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(
                    Icons.grade_rounded,
                    size: 16,
                    color: _filterStatus == AssignmentStatus.graded
                        ? colors.onPrimary
                        : Colors.green.shade700,
                  ),
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
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 56,
                          color: colors.onSurfaceVariant.withAlpha(120),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filterStatus != null || _searchQuery.isNotEmpty
                              ? 'No matching assignments found'
                              : 'All caught up! No assignments right now.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
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
                      spacing: 12,
                      runSpacing: 12,
                      children: filtered.map((item) {
                        final cardWidth = (constraints.maxWidth - 12) / 2;
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
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
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

  Color _getStatusColor(AssignmentStatus status, ColorScheme colors) {
    switch (status) {
      case AssignmentStatus.pending:
        return Colors.amber.shade700;
      case AssignmentStatus.submitted:
        return Colors.blue.shade600;
      case AssignmentStatus.graded:
        return Colors.green.shade600;
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
    final statusColor = _getStatusColor(assignment.status, colors);
    final statusLabel = _getStatusLabel(assignment.status);
    final isGraded = assignment.status == AssignmentStatus.graded;
    final isSubmitted = assignment.status == AssignmentStatus.submitted;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Subject & Status Chip
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    assignment.subject,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(28),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(assignment.status),
                        size: 13,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              assignment.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
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
                      fontWeight: FontWeight.w500,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${assignment.points} pts',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            if (isGraded && assignment.marks != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.grade_rounded,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Score: ${assignment.marks} / ${assignment.points}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (assignment.feedback != null) ...[
                      const Spacer(),
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: Colors.green,
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
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  : isSubmitted
                  ? OutlinedButton.icon(
                      onPressed: () => _openSubmitDialog(context),
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('View / Resubmit'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: () => _openSubmitDialog(context),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Submit Assignment'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
            ),
          ],
        ),
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
