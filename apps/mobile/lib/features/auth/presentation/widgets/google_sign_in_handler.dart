import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/branding/app_branding.dart';
import 'package:mobile/core/theme/clay_theme.dart';
import '../../application/auth_providers.dart';
import '../../domain/auth_repository.dart';

class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;

    // Blue #4285F4
    final bluePath = Path()
      ..moveTo(23.49 * s, 12.28 * s)
      ..cubicTo(23.49 * s, 11.43 * s, 23.42 * s, 10.61 * s, 23.28 * s, 9.82 * s)
      ..lineTo(12.0 * s, 9.82 * s)
      ..lineTo(12.0 * s, 14.47 * s)
      ..lineTo(18.44 * s, 14.47 * s)
      ..cubicTo(18.16 * s, 15.96 * s, 17.32 * s, 17.23 * s, 16.05 * s, 18.08 * s)
      ..lineTo(16.05 * s, 21.08 * s)
      ..lineTo(19.92 * s, 21.08 * s)
      ..cubicTo(22.18 * s, 19.0 * s, 23.49 * s, 15.93 * s, 23.49 * s, 12.28 * s)
      ..close();
    canvas.drawPath(
      bluePath,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..isAntiAlias = true,
    );

    // Green #34A853
    final greenPath = Path()
      ..moveTo(12.0 * s, 24.0 * s)
      ..cubicTo(15.24 * s, 24.0 * s, 17.95 * s, 22.92 * s, 19.93 * s, 21.09 * s)
      ..lineTo(16.06 * s, 18.09 * s)
      ..cubicTo(14.98 * s, 18.81 * s, 13.61 * s, 19.25 * s, 12.0 * s, 19.25 * s)
      ..cubicTo(8.87 * s, 19.25 * s, 6.22 * s, 17.14 * s, 5.27 * s, 14.29 * s)
      ..lineTo(1.25 * s, 14.29 * s)
      ..lineTo(1.25 * s, 17.38 * s)
      ..cubicTo(3.28 * s, 21.43 * s, 7.34 * s, 24.0 * s, 12.0 * s, 24.0 * s)
      ..close();
    canvas.drawPath(
      greenPath,
      Paint()
        ..color = const Color(0xFF34A853)
        ..isAntiAlias = true,
    );

    // Yellow #FBBC05
    final yellowPath = Path()
      ..moveTo(5.27 * s, 14.29 * s)
      ..cubicTo(5.02 * s, 13.57 * s, 4.89 * s, 12.8 * s, 4.89 * s, 12.0 * s)
      ..cubicTo(4.89 * s, 11.2 * s, 5.03 * s, 10.43 * s, 5.27 * s, 9.71 * s)
      ..lineTo(5.27 * s, 6.6 * s)
      ..lineTo(1.25 * s, 6.6 * s)
      ..cubicTo(0.45 * s, 8.19 * s, 0.0, 9.99 * s, 0.0, 12.0 * s)
      ..cubicTo(0.0, 14.01 * s, 0.45 * s, 15.81 * s, 1.25 * s, 17.4 * s)
      ..lineTo(5.27 * s, 14.29 * s)
      ..close();
    canvas.drawPath(
      yellowPath,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..isAntiAlias = true,
    );

    // Red #EA4335
    final redPath = Path()
      ..moveTo(12.0 * s, 4.75 * s)
      ..cubicTo(13.77 * s, 4.75 * s, 15.35 * s, 5.36 * s, 16.6 * s, 6.55 * s)
      ..lineTo(20.02 * s, 3.13 * s)
      ..cubicTo(17.95 * s, 1.19 * s, 15.24 * s, 0.0, 12.0 * s, 0.0)
      ..cubicTo(7.34 * s, 0.0, 3.28 * s, 2.57 * s, 1.25 * s, 6.6 * s)
      ..lineTo(5.27 * s, 9.71 * s)
      ..cubicTo(6.22 * s, 6.86 * s, 8.87 * s, 4.75 * s, 12.0 * s, 4.75 * s)
      ..close();
    canvas.drawPath(
      redPath,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Official multi-coloured "G" vector logo
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const GoogleLogoPainter(),
    );
  }
}

/// Reusable Google Sign-In button following official brand guidelines
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in is not configured in this build. Use email/password or Try demo.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? ClayTokens.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? Colors.white24 : const Color(0xFFDADCE0),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _busy ? null : _handleGoogleSignIn,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GoogleLogo(size: 20),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF3C4043),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
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
                    'Welcome to ${AppBranding.appName}!',
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
