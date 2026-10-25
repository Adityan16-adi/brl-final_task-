import 'package:flutter/material.dart';

/// A prominent, cohesive badge informing users that the displayed content
/// originates from offline demonstration records or fallback mock datasets.
class DemoDataBadge extends StatelessWidget {
  const DemoDataBadge({
    super.key,
    this.message = 'Demo Data — Backend offline or fallback dataset active',
    this.compact = false,
  });

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF332A15) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.science_outlined,
            size: compact ? 14 : 16,
            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
