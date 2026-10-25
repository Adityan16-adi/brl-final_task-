import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/clay_theme.dart';
import '../../application/auth_providers.dart';
import '../../domain/auth_repository.dart';

/// Reusable Claymorphic "Continue with Google" button and first-time role selection modal.
class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({
    super.key,
    this.text = 'Continue with Google',
    this.onSuccess,
  });

  final String text;
  final VoidCallback? onSuccess;

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _busy = false;

  Future<void> _handleGoogleSignIn() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.signInWithGoogle();

      if (!mounted) return;

      if (result.needsRoleSelection) {
        setState(() => _busy = false);
        await showRoleSelectionSheet(context, ref, result, widget.onSuccess);
        return;
      }

      if (result.user != null) {
        widget.onSuccess?.call();
        if (context.mounted) {
          context.go('/overview');
        }
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      showGoogleUnavailableDialog(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showGoogleUnavailableDialog(context, 'Google Sign-In error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClayButton(
      isFullWidth: true,
      isLoading: _busy,
      onPressed: _busy ? null : _handleGoogleSignIn,
      icon: Icons.g_mobiledata_rounded,
      color: isDark ? ClayTokens.darkSurface : Colors.white,
      textColor: isDark ? Colors.white : ClayTokens.darkInk,
      gradient: LinearGradient(
        colors: isDark
            ? [const Color(0xFF26243A), const Color(0xFF1E1C2E)]
            : [Colors.white, const Color(0xFFF7F7FA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Text(widget.text),
    );
  }
}

/// Friendly dialog when Google services or credentials are not configured on the client
void showGoogleUnavailableDialog(BuildContext context, String message) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? ClayTokens.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ClayTokens.radiusMedium),
      ),
      title: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: ClayTokens.deepIndigo, size: 24),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Google Sign-In Notice',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E2B45) : const Color(0xFFF0EDFA),
              borderRadius: BorderRadius.circular(ClayTokens.radiusSmall),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 16, color: ClayTokens.deepIndigo),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Email/Password login and Demo Mode are fully operational.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK, Got It'),
        ),
      ],
    ),
  );
}

/// Role selection sheet for first-time Google Sign-In users
Future<void> showRoleSelectionSheet(
  BuildContext context,
  WidgetRef ref,
  GoogleAuthResult authResult,
  VoidCallback? onSuccess,
) async {
  UserRole selectedRole = UserRole.student;
  final codeController = TextEditingController();
  String? errorText;
  bool submitting = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          Future<void> completeRegistration() async {
            if (submitting) return;
            setSheetState(() {
              submitting = true;
              errorText = null;
            });

            try {
              final authRepo = ref.read(authRepositoryProvider);
              final res = await authRepo.signInWithGoogle(
                role: selectedRole,
                teacherCode: selectedRole == UserRole.teacher ? codeController.text.trim() : null,
                idTokenOverride: authResult.idToken,
              );

              if (res.user != null) {
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                onSuccess?.call();
                if (context.mounted) {
                  context.go('/overview');
                }
              }
            } on AuthFailure catch (e) {
              setSheetState(() {
                errorText = e.message;
                submitting = false;
              });
            } catch (e) {
              setSheetState(() {
                errorText = 'Registration error: $e';
                submitting = false;
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? ClayTokens.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 18),
                  Text(
                    'Welcome to Smart Classroom!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : ClayTokens.darkInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select your account role to complete sign in for ${authResult.email ?? "your Google account"}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : ClayTokens.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Role selector
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedRole = UserRole.student),
                          child: ClayContainer(
                            depth: selectedRole == UserRole.student ? 6 : 2,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            color: selectedRole == UserRole.student
                                ? (isDark ? const Color(0xFF3B3363) : const Color(0xFFEAE6FC))
                                : (isDark ? ClayTokens.darkCard : const Color(0xFFF7F6FC)),
                            borderRadius: BorderRadius.circular(ClayTokens.radiusSmall),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  color: selectedRole == UserRole.student
                                      ? ClayTokens.deepIndigo
                                      : Colors.grey,
                                  size: 26,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Student',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: selectedRole == UserRole.student
                                        ? ClayTokens.deepIndigo
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedRole = UserRole.teacher),
                          child: ClayContainer(
                            depth: selectedRole == UserRole.teacher ? 6 : 2,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            color: selectedRole == UserRole.teacher
                                ? (isDark ? const Color(0xFF3B3363) : const Color(0xFFEAE6FC))
                                : (isDark ? ClayTokens.darkCard : const Color(0xFFF7F6FC)),
                            borderRadius: BorderRadius.circular(ClayTokens.radiusSmall),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.co_present_rounded,
                                  color: selectedRole == UserRole.teacher
                                      ? ClayTokens.deepIndigo
                                      : Colors.grey,
                                  size: 26,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Teacher',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: selectedRole == UserRole.teacher
                                        ? ClayTokens.deepIndigo
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (selectedRole == UserRole.teacher) ...[
                    const SizedBox(height: 16),
                    ClayTextField(
                      controller: codeController,
                      labelText: 'Teacher Provisioning Code',
                      hintText: 'Enter teacher signup code',
                      prefixIcon: const Icon(Icons.key_rounded, size: 20),
                    ),
                  ],

                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),
                  ClayButton(
                    isFullWidth: true,
                    isLoading: submitting,
                    onPressed: submitting ? null : completeRegistration,
                    child: const Text('Complete Sign In'),
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
