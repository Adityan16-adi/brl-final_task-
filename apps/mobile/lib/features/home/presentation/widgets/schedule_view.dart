import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/clay_theme.dart';
import '../../../../core/widgets/demo_data_badge.dart';
import '../../../auth/application/auth_providers.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';
import '../notification_providers.dart';
import 'notifications_sheet.dart';

class ScheduleView extends ConsumerStatefulWidget {
  const ScheduleView({super.key});

  @override
  ConsumerState<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends ConsumerState<ScheduleView> {
  int _filterIndex = 0; // 0: All, 1: Today, 2: Lectures, 3: Deadlines
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<ScheduleItem> _getItemsForDay(DateTime day, List<ScheduleItem> items) {
    final now = DateTime.now();
    return items.where((item) {
      if (item.date != null) {
        return _isSameDay(item.date!, day);
      }
      if (item.isToday && _isSameDay(day, now)) {
        return true;
      }
      if (item.time.toLowerCase().contains('tomorrow') &&
          _isSameDay(day, now.add(const Duration(days: 1)))) {
        return true;
      }
      final dayNames = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];
      final dayAbbrs = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
      final idx = day.weekday - 1;
      final fullText = '${item.time} ${item.location} ${item.title}'.toLowerCase();
      if (fullText.contains(dayNames[idx]) || fullText.contains(dayAbbrs[idx])) {
        return true;
      }
      return false;
    }).toList();
  }

  void _onDaySelected(DateTime day) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDate = day;
      if (_filterIndex == 1 && !_isSameDay(day, DateTime.now())) {
        _filterIndex = 0;
      }
    });
  }

  void _goToToday() {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
      if (_filterIndex == 1) {
        _filterIndex = 0;
      }
    });
  }

  void _previousMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleProvider);
    final currentUser = ref.watch(currentUserProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(scheduleProvider),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              // Top filter chips and Notification bell
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
                            onSelected: (_) {
                              HapticFeedback.lightImpact();
                              setState(() => _filterIndex = 0);
                            },
                          ),
                          const SizedBox(width: 6),
                          FilterChip(
                            avatar: const Icon(Icons.today_rounded, size: 15),
                            label: const Text('Today'),
                            selected: _filterIndex == 1,
                            onSelected: (_) {
                              _goToToday();
                              setState(() => _filterIndex = 1);
                            },
                          ),
                          const SizedBox(width: 6),
                          FilterChip(
                            label: const Text('Lectures'),
                            selected: _filterIndex == 2,
                            onSelected: (_) {
                              HapticFeedback.lightImpact();
                              setState(() => _filterIndex = 2);
                            },
                          ),
                          const SizedBox(width: 6),
                          FilterChip(
                            label: const Text('Deadlines'),
                            selected: _filterIndex == 3,
                            onSelected: (_) {
                              HapticFeedback.lightImpact();
                              setState(() => _filterIndex = 3);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.notifications_rounded, size: 20),
                        tooltip: 'Reminders & Alerts',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          showInAppNotificationsSheet(context);
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: ClayTokens.pragtiOrange,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (currentUser?.isDemo == true)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: DemoDataBadge(
                    message: 'Demo Data — Offline demonstration mode active',
                  ),
                ),

              scheduleAsync.when(
                data: (allSchedule) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Month View Calendar Card
                      _buildMonthCalendar(context, allSchedule, isDark, colors),
                      const SizedBox(height: 16),

                      // Selected day header and list of items
                      _buildDayEventsSection(context, allSchedule, isDark, colors),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
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
        ),
      ),
    );
  }

  Widget _buildMonthCalendar(
    BuildContext context,
    List<ScheduleItem> schedule,
    bool isDark,
    ColorScheme colors,
  ) {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final monthName = _monthNames[month - 1];
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1 = Mon, 7 = Sun
    final leadingBlanks = firstWeekday - 1; // 0..6
    final totalCells = leadingBlanks + daysInMonth;
    final trailingBlanks = (7 - (totalCells % 7)) % 7;
    final cellCount = totalCells + trailingBlanks;
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ClayTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        children: [
          // Month navigation bar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Previous month',
                visualDensity: VisualDensity.compact,
                onPressed: _previousMonth,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$monthName $year',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : ClayTokens.navy,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Next month',
                visualDensity: VisualDensity.compact,
                onPressed: _nextMonth,
              ),
              IconButton(
                icon: const Icon(Icons.today_rounded, size: 20),
                tooltip: 'Current month',
                visualDensity: VisualDensity.compact,
                onPressed: _goToToday,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Weekday column headers (Mon..Sun)
          Row(
            children: _weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // 7-day Column Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              if (index < leadingBlanks || index >= leadingBlanks + daysInMonth) {
                return const SizedBox.shrink();
              }
              final dayNumber = index - leadingBlanks + 1;
              final dayDate = DateTime(year, month, dayNumber);
              final isToday = _isSameDay(dayDate, now);
              final isSelected = _isSameDay(dayDate, _selectedDate);

              final dayItems = _getItemsForDay(dayDate, schedule);
              final hasClasses = dayItems.any((i) => i.type.toLowerCase() != 'deadline');
              final hasDeadlines = dayItems.any((i) => i.type.toLowerCase() == 'deadline');

              Color textColor;
              if (isSelected) {
                textColor = Colors.white;
              } else if (isToday) {
                textColor = ClayTokens.brightBlue;
              } else {
                textColor = isDark ? Colors.white : ClayTokens.navy;
              }

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _onDaySelected(dayDate),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ClayTokens.brightBlue
                        : (isToday
                            ? ClayTokens.brightBlue.withValues(alpha: isDark ? 0.15 : 0.08)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(color: ClayTokens.brightBlue, width: 1.2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Indicator dots: Blue for class, Orange for deadline
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasClasses)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white : ClayTokens.brightBlue,
                              ),
                            ),
                          if (hasDeadlines)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: ClayTokens.pragtiOrange,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Legend for indicator dots
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: ClayTokens.brightBlue,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Class / Lecture',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: ClayTokens.pragtiOrange,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Assignment Deadline',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
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

  Widget _buildDayEventsSection(
    BuildContext context,
    List<ScheduleItem> schedule,
    bool isDark,
    ColorScheme colors,
  ) {
    final now = DateTime.now();
    final isSelectedToday = _isSameDay(_selectedDate, now);

    // Get items for selected day, filtered by chip if active
    final dayAllItems = _getItemsForDay(_selectedDate, schedule);
    final displayedItems = dayAllItems.where((s) {
      if (_filterIndex == 2) return s.type.toLowerCase() != 'deadline';
      if (_filterIndex == 3) return s.type.toLowerCase() == 'deadline';
      return true;
    }).toList();

    final dayName = _weekdays[_selectedDate.weekday - 1];
    final monthName = _monthNames[_selectedDate.month - 1];
    final dateTitle = isSelectedToday
        ? 'Today, $dayName ${_selectedDate.day} $monthName'
        : '$dayName, ${_selectedDate.day} $monthName';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                dateTitle,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : ClayTokens.navy,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? ClayTokens.darkElevated : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
                  width: 1,
                ),
              ),
              child: Text(
                '${displayedItems.length} ${displayedItems.length == 1 ? "event" : "events"}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (displayedItems.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? ClayTokens.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ClayTokens.brightBlue.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      size: 26,
                      color: ClayTokens.brightBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No sessions or deadlines for this day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : ClayTokens.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enjoy your break or review earlier coursework.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                    ),
                  ),
                  if (!isSelectedToday) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      icon: const Icon(Icons.today_rounded, size: 15),
                      label: const Text('Go to current schedule'),
                      onPressed: _goToToday,
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          ...displayedItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ScheduleCard(item: item),
            );
          }),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.item});

  final ScheduleItem item;

  bool get _isDeadline => item.type.toLowerCase() == 'deadline';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = _isDeadline ? ClayTokens.pragtiOrange : ClayTokens.brightBlue;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ClayTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ClayTokens.darkBorder : ClayTokens.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isDeadline ? Icons.timer_outlined : Icons.menu_book_rounded,
                      size: 13,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.type,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.subject,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: ClayTokens.pragtiNavy,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'TODAY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : ClayTokens.navy,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 14,
                color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Session "${item.title}" saved to in-app schedule! (System calendar sync requires device calendar permissions)',
                      ),
                      backgroundColor: ClayTokens.pragtiNavy,
                    ),
                  );
                },
                icon: const Icon(Icons.event_available_rounded, size: 15),
                label: const Text('In-App Reminder', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
