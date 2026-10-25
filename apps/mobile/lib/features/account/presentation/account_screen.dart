import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/clay_theme.dart';
import '../../auth/application/auth_providers.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  static const Color _coral = Color(0xFFEF4444);

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text(
            'Are you sure you want to sign out of your account? Your offline sessions are preserved.'),
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

    if (confirm == true && mounted) {
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isTeacher = user?.isTeacher == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Profile Hero Card
          ClayCard(
            depth: 4,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ClayContainer(
                  width: 80,
                  height: 80,
                  depth: 5,
                  gradient: LinearGradient(
                    colors: isTeacher
                        ? [const Color(0xFF9333EA), const Color(0xFF6B21A8)]
                        : [const Color(0xFF6356F5), const Color(0xFF473BB8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'No email',
                  style: const TextStyle(
                    fontSize: 13,
                    color: ClayTokens.secondaryText,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: isTeacher
                        ? const Color(0xFFF3E8FF)
                        : const Color(0xFFEDEAF8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isTeacher ? 'Instructor / Educator' : 'Student Learner',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isTeacher
                          ? const Color(0xFF7E22CE)
                          : ClayTokens.deepIndigo,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Account Details Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'ACCOUNT DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: ClayTokens.secondaryText,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ClayCard(
            depth: 3,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.badge_rounded,
                      color: ClayTokens.deepIndigo),
                  title: const Text('User ID',
                      style: TextStyle(fontSize: 13, color: ClayTokens.secondaryText)),
                  subtitle: Text(
                    user?.uid ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined,
                      color: ClayTokens.deepIndigo),
                  title: const Text('Email Address',
                      style: TextStyle(fontSize: 13, color: ClayTokens.secondaryText)),
                  subtitle: Text(
                    user?.email ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_user_rounded,
                      color: ClayTokens.mintDark),
                  title: const Text('Status',
                      style: TextStyle(fontSize: 13, color: ClayTokens.secondaryText)),
                  subtitle: const Text(
                    'Active Account (Synchronized)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ClayTokens.mintDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          ClayButton(
            isFullWidth: true,
            color: _coral,
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            ),
            icon: Icons.logout_rounded,
            onPressed: _handleSignOut,
            child: const Text('Sign Out of Account'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
