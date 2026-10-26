import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/clay_theme.dart';
import '../notification_providers.dart';

/// Modal bottom sheet showing in-app notifications with "Mark all as read"
/// and "You're all caught up" empty state.
void showInAppNotificationsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _NotificationsSheetContent(),
  );
}

class _NotificationsSheetContent extends ConsumerWidget {
  const _NotificationsSheetContent();

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.classReminder:
        return Icons.school_rounded;
      case NotificationType.assignmentDue:
        return Icons.timer_outlined;
      case NotificationType.newGrade:
        return Icons.verified_outlined;
      case NotificationType.announcement:
        return Icons.campaign_outlined;
    }
  }

  Color _getColor(NotificationType type) {
    switch (type) {
      case NotificationType.classReminder:
        return ClayTokens.brightBlue;
      case NotificationType.assignmentDue:
        return ClayTokens.pragtiOrange;
      case NotificationType.newGrade:
        return const Color(0xFF10B981);
      case NotificationType.announcement:
        return ClayTokens.brightBlue;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(inAppNotificationsProvider);
    final notifications = notificationsAsync.value ?? [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? ClayTokens.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Classroom Reminders & Alerts',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : ClayTokens.navy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'In-app notifications & updates',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? ClayTokens.darkSecondary : ClayTokens.lightSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (notifications.any((n) => !n.isRead))
                TextButton(
                  onPressed: () {
                    ref.read(inAppNotificationsProvider.notifier).markAllAsRead();
                  },
                  child: const Text('Mark all as read', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.done_all_rounded,
                      size: 44,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "You're all caught up",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : ClayTokens.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notifications.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF243049) : const Color(0xFFF1F5F9),
                ),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final color = _getColor(notif.type);
                  final icon = _getIcon(notif.type);

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isDark ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 18, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                        color: isDark ? Colors.white : ClayTokens.navy,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatTime(notif.timestamp),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white38 : ClayTokens.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                notif.body,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : ClayTokens.secondaryText,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!notif.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: ClayTokens.pragtiOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
