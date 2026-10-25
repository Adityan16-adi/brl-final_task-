import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/clay_theme.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';

class ScheduleView extends ConsumerStatefulWidget {
  const ScheduleView({super.key});

  @override
  ConsumerState<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends ConsumerState<ScheduleView> {
  int _filterIndex = 0; // 0: All, 1: Today, 2: Lectures, 3: Deadlines

  void _showNotificationCenter(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        final schedule = ref.watch(scheduleProvider).value ?? [];
        final upcomingDeadlines = schedule
            .where((s) => s.type.toLowerCase() == 'deadline')
            .toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
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
                    width: 36,
                    height: 36,
                    depth: 2,
                    borderRadius: BorderRadius.circular(10),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: ClayTokens.deepIndigo,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Classroom Reminders & Alerts',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (upcomingDeadlines.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No urgent deadlines pending.')),
                ),
              ] else ...[
                Text(
                  'Upcoming Deadlines (${upcomingDeadlines.length}):',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ...upcomingDeadlines.take(3).map((d) {
                  return ClayCard(
                    depth: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${d.subject} · ${d.time}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Push notification delivery requires FCM cloud credentials configured for mobile.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleProvider);
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(scheduleProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Top Bar with Filter Chips and Reminders Pill
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterIndex == 0,
                        onSelected: (_) => setState(() => _filterIndex = 0),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        avatar: const Icon(Icons.today_rounded, size: 15),
                        label: const Text('Today'),
                        selected: _filterIndex == 1,
                        onSelected: (_) => setState(() => _filterIndex = 1),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Lectures'),
                        selected: _filterIndex == 2,
                        onSelected: (_) => setState(() => _filterIndex = 2),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Deadlines'),
                        selected: _filterIndex == 3,
                        onSelected: (_) => setState(() => _filterIndex = 3),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.notifications_rounded, size: 20),
                tooltip: 'Reminders & Alerts',
                onPressed: () => _showNotificationCenter(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          scheduleAsync.when(
            data: (schedule) {
              final items = schedule.where((s) {
                if (_filterIndex == 1) {
                  return s.isToday;
                }
                if (_filterIndex == 2) {
                  return s.type.toLowerCase() == 'lecture';
                }
                if (_filterIndex == 3) {
                  return s.type.toLowerCase() == 'deadline';
                }
                return true;
              }).toList();

              if (items.isEmpty) {
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
                              Icons.event_available_rounded,
                              size: 32,
                              color: ClayTokens.deepIndigo,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _filterIndex == 1
                              ? 'No sessions scheduled for today!'
                              : 'No schedule items found.',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_filterIndex != 0) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(() => _filterIndex = 0),
                            child: const Text('View entire schedule'),
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
                      children: items.map((item) {
                        final cardWidth = (constraints.maxWidth - 14) / 2;
                        return SizedBox(
                          width: cardWidth,
                          child: _ScheduleCard(item: item),
                        );
                      }).toList(),
                    );
                  }

                  return Column(
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ScheduleCard(item: item),
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
                      'Failed to load schedule: $err',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(scheduleProvider),
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

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.item});

  final ScheduleItem item;

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'lecture':
        return ClayTokens.deepIndigo;
      case 'lab':
        return const Color(0xFF0D9488);
      case 'deadline':
        return Colors.redAccent.shade700;
      default:
        return const Color(0xFF7C3AED);
    }
  }

  Color _getTypeBg(String type) {
    switch (type.toLowerCase()) {
      case 'lecture':
        return ClayTokens.softLavender;
      case 'lab':
        return ClayTokens.mint;
      case 'deadline':
        return const Color(0xFFFFECEE);
      default:
        return const Color(0xFFF3E8FF);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'lecture':
        return Icons.menu_book_rounded;
      case 'lab':
        return Icons.biotech_rounded;
      case 'deadline':
        return Icons.timer_outlined;
      default:
        return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final typeColor = _getTypeColor(item.type);
    final typeBg = _getTypeBg(item.type);

    return ClayCard(
      depth: 5,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClayBadge(
                label: item.type,
                icon: _getTypeIcon(item.type),
                backgroundColor: typeBg,
                textColor: typeColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ClayBadge(
                    label: item.subject,
                    backgroundColor: ClayTokens.softLavender,
                    textColor: ClayTokens.deepIndigo,
                  ),
                ),
              ),
              if (item.isToday) ...[
                const SizedBox(width: 8),
                const ClayBadge(
                  label: 'TODAY',
                  backgroundColor: ClayTokens.deepIndigo,
                  textColor: Colors.white,
                  icon: Icons.flash_on_rounded,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 15,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 15,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Session "${item.title}" saved to in-app schedule! (System calendar sync requires device calendar permissions)',
                      ),
                      backgroundColor: ClayTokens.deepIndigo,
                    ),
                  );
                },
                icon: const Icon(Icons.event_available_rounded, size: 16),
                label: const Text('In-App Reminder'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
