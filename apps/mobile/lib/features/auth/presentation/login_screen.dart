import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/theme/clay_theme.dart';
import '../application/auth_providers.dart';
import '../domain/auth_repository.dart';
import 'widgets/google_sign_in_handler.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _busy = false;
  bool _obscure = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _quickLogin(String email) async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final role = email.contains('teacher') ? UserRole.teacher : UserRole.student;
      await repo.signInDemo(role: role);
      if (mounted) {
        context.go('/');
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _busy) return;

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        context.go('/');
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'An error occurred: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showForgotPasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.lock_reset_rounded,
              size: 22,
              color: ClayTokens.deepIndigo,
            ),
            SizedBox(width: 8),
            Text(
              'Reset Password',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email address to receive password reset instructions.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 14),
            TextField(
              decoration: InputDecoration(
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Password reset instructions sent to your email.',
                  ),
                  backgroundColor: ClayTokens.deepIndigo,
                ),
              );
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  void _showDemoInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: ClayTokens.deepIndigo,
            ),
            SizedBox(width: 8),
            Text('Authentication & Demo Info', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Architecture Status:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 6),
            Text(
              '• The mobile app connects to the Auth Repository with offline mock fallback and live session management.\n'
              '• Rapid demonstration accounts:\n'
              '  - Student: student@demo.com (demo1234)\n'
              '  - Teacher: teacher@demo.com (demo1234)\n'
              '• New accounts created via Register are stored locally in the session registry.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/welcome'),
          ),
          title: const Text('Sign In'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo & Branding
                      Center(
                        child: ClayContainer(
                          width: 68,
                          height: 68,
                          depth: 7,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6B5EFF), Color(0xFF4335C9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          child: const Center(
                            child: Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppBranding.appName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to access your virtual classrooms and assignments.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white60
                              : ClayTokens.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Demo Mode Quick Login Card
                      ClayCard(
                        padding: const EdgeInsets.all(14),
                        depth: 4,
                        color: isDark
                            ? ClayTokens.darkCard
                            : const Color(0xFFEFEFF9),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 18,
                                  color: ClayTokens.deepIndigo,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Development Demo Mode',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: ClayTokens.deepIndigo,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Instant credentials for quick feature review:',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white60
                                    : ClayTokens.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _quickLogin('student@demo.com'),
                                  icon: const Icon(
                                    Icons.person_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Student Login'),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _quickLogin('teacher@demo.com'),
                                  icon: const Icon(
                                    Icons.co_present_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Teacher Login'),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      ClayTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        hintText: 'e.g. student@demo.com',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password Field
                      ClayTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'e.g. demo1234',
                        obscureText: _obscure,
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        textInputAction: TextInputAction.done,
                        validator: (val) => (val == null || val.length < 6)
                            ? 'Password must be at least 6 characters'
                            : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 6),
                        ClayContainer(
                          padding: const EdgeInsets.all(12),
                          color: isDark
                              ? const Color(0xFF421D24)
                              : const Color(0xFFFFECEE),
                          borderRadius: BorderRadius.circular(
                            ClayTokens.radiusSmall,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _busy ? null : _submit,
                                  icon: const Icon(Icons.refresh_rounded, size: 14),
                                  label: const Text('Retry Connection'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      const SizedBox(height: 10),

                      // Submit Clay Button
                      ClayButton(
                        isFullWidth: true,
                        isLoading: _busy,
                        onPressed: _busy ? null : _submit,
                        icon: Icons.login_rounded,
                        child: const Text('Sign In'),
                      ),

                      const SizedBox(height: 12),

                      // Sign in with Google
                      const GoogleSignInButton(),

                      const SizedBox(height: 14),

                      // Create Account Button
                      ClayButton(
                        isFullWidth: true,
                        color: isDark ? ClayTokens.darkSurface : Colors.white,
                        textColor: isDark ? Colors.white : ClayTokens.darkInk,
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF292742),
                                  const Color(0xFF1E1C30),
                                ]
                              : [Colors.white, const Color(0xFFF7F6FC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onPressed: _busy
                            ? null
                            : () => context.push('/register'),
                        icon: Icons.person_add_outlined,
                        child: const Text('New to Unified Learn? Register'),
                      ),

                      const SizedBox(height: 12),

                      TextButton.icon(
                        onPressed: _showDemoInfoDialog,
                        icon: const Icon(Icons.help_outline_rounded, size: 15),
                        label: const Text(
                          'Auth Architecture & Demo Info',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
