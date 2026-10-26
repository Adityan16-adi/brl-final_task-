import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/branding/app_branding.dart';
import '../../../../core/branding/brand_widgets.dart';
import '../../../../core/theme/clay_theme.dart';
import '../../../auth/application/auth_providers.dart';

/// Clean, focused drawer holding Profile, Settings, Help, and Sign Out.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    this.currentTabIndex = 0,
    this.onSelectTab,
  });

  final int currentTabIndex;
  final ValueChanged<int>? onSelectTab;

  static const Color _coral = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isTeacher = user?.isTeacher == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header Profile Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(ClayTokens.radiusMedium),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/account');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Theme.of(context).colorScheme.outlineVariant
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const BrandLogo(
                            size: 22,
                            useMarkOnly: true,
                            onCard: false,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            AppBranding.appName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '• ${AppBranding.tagline}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: ClayTokens.pragtiOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(user.avatarUrl!),
                              backgroundColor: Colors.transparent,
                            )
                          else
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isTeacher ? const Color(0xFF8B5CF6) : ClayTokens.brightBlue,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  user?.name.isNotEmpty == true
                                      ? user!.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'User',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.email ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : ClayTokens.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? (isTeacher
                                            ? ClayTokens.pragtiNavy.withValues(alpha: 0.5)
                                            : ClayTokens.brightBlue.withValues(alpha: 0.15))
                                        : (isTeacher
                                            ? const Color(0xFFEFF6FF)
                                            : const Color(0xFFEEF4FF)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isTeacher ? 'Teacher' : 'Student',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isTeacher
                                          ? (isDark ? Colors.white70 : ClayTokens.pragtiNavy)
                                          : ClayTokens.brightBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 8),

            // Navigation Actions: Profile, Settings, Help
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.person_outline_rounded, size: 22),
                    title: const Text('My Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/account');
                    },
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.settings_outlined, size: 22),
                    title: const Text('Settings & Preferences', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/settings');
                    },
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.help_outline_rounded, size: 22),
                    title: const Text('Help Desk & FAQ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/help');
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // Sign out action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.logout_rounded, size: 22, color: _coral),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _coral,
                    fontSize: 14,
                  ),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _coral,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
