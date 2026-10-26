import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_message_helper.dart';
import '../../../../core/theme/clay_theme.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/auth_repository.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  static const Color _coral = Color(0xFFEF4444);
  bool _isSaving = false;

  Future<void> _showEditProfileDialog(AppUser? user) async {
    if (user == null) return;
    final nameCtrl = TextEditingController(text: user.name);
    final avatarCtrl = TextEditingController(text: user.avatarUrl ?? '');
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Edit Account Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClayTextField(
                      controller: nameCtrl,
                      labelText: 'Display Name',
                      hintText: 'Enter your full name',
                      prefixIcon: const Icon(Icons.person_rounded),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please provide your name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    ClayTextField(
                      controller: avatarCtrl,
                      labelText: 'Profile Photo URL',
                      hintText: 'https://images.unsplash.com/... or Cloudinary URL',
                      prefixIcon: const Icon(Icons.photo_camera_rounded),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Preset Avatar Suggestions:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ClayTokens.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.school_rounded, size: 14),
                          label: const Text('Academic', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setSheetState(() {
                              avatarCtrl.text =
                                  'https://api.dicebear.com/7.x/bottts/png?seed=${user.email}';
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.palette_rounded, size: 14),
                          label: const Text('Creative', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setSheetState(() {
                              avatarCtrl.text =
                                  'https://api.dicebear.com/7.x/notionists/png?seed=${user.name}';
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.clear_rounded, size: 14),
                          label: const Text('Reset', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setSheetState(() {
                              avatarCtrl.text = '';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.of(sheetCtx).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClayButton(
                            isLoading: _isSaving,
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setSheetState(() => _isSaving = true);
                                    try {
                                      await ref
                                          .read(authRepositoryProvider)
                                          .updateProfile(
                                            name: nameCtrl.text.trim(),
                                            avatarUrl: avatarCtrl.text.trim(),
                                          );
                                      if (sheetCtx.mounted) {
                                        Navigator.of(sheetCtx).pop();
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Profile updated successfully!'),
                                            backgroundColor: ClayTokens.mintDark,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setSheetState(() => _isSaving = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(ErrorMessageHelper.format(e, fallback: 'Failed to update profile. Please try again.')),
                                            backgroundColor: _coral,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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
                  padding: EdgeInsets.zero,
                  color: isTeacher ? ClayTokens.pragtiBlue : ClayTokens.pragtiNavy,
                  borderRadius: BorderRadius.circular(28),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                        ? Image.network(
                            user.avatarUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Text(
                                user.name.isNotEmpty == true
                                    ? user.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Center(
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
                          ? ClayTokens.pragtiBlue
                          : ClayTokens.pragtiNavy,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ClayButton(
                  icon: Icons.edit_rounded,
                  onPressed: () => _showEditProfileDialog(user),
                  child: const Text('Edit Profile'),
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
