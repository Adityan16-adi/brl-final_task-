import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/branding/brand_widgets.dart';
import '../../../core/errors/error_message_helper.dart';
import '../../../core/theme/clay_theme.dart';
import '../application/auth_providers.dart';
import '../domain/auth_repository.dart';
import 'widgets/google_sign_in_handler.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _role = UserRole.student;
  bool _busy = false;
  bool _obscure = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _busy) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match. Please verify.');
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
      );

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = ErrorMessageHelper.format(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/welcome'),
          ),
          title: const Text('Create Account'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      ClayContainer(
                        padding: const EdgeInsets.all(20),
                        depth: 6,
                        child: Column(
                          children: [
                            const BrandLogo(
                              size: 44,
                              useMarkOnly: true,
                              onCard: true,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Join ${AppBranding.appName}',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select your role and start your collaborative learning journey.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white60
                                    : ClayTokens.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Role Selector Clay Cards
                      const Text(
                        'Select Your Role:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClayCard(
                              onTap: () =>
                                  setState(() => _role = UserRole.student),
                              color: _role == UserRole.student
                                  ? (_role == UserRole.student
                                        ? (isDark
                                              ? const Color(0xFF2E2B54)
                                              : ClayTokens.softLavender)
                                        : null)
                                  : null,
                              border: _role == UserRole.student
                                  ? Border.all(
                                      color: ClayTokens.deepIndigo,
                                      width: 2,
                                    )
                                  : null,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    size: 28,
                                    color: _role == UserRole.student
                                        ? ClayTokens.deepIndigo
                                        : (isDark
                                              ? Colors.white54
                                              : ClayTokens.secondaryText),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Student',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: _role == UserRole.student
                                          ? ClayTokens.deepIndigo
                                          : (isDark
                                                ? Colors.white70
                                                : ClayTokens.darkInk),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Join & submit work',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white38
                                          : ClayTokens.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClayCard(
                              onTap: () =>
                                  setState(() => _role = UserRole.teacher),
                              color: _role == UserRole.teacher
                                  ? (isDark
                                        ? const Color(0xFF382650)
                                        : const Color(0xFFF3E8FF))
                                  : null,
                              border: _role == UserRole.teacher
                                  ? const Border.fromBorderSide(
                                      BorderSide(
                                        color: Color(0xFF8B5CF6),
                                        width: 2,
                                      ),
                                    )
                                  : null,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.co_present_rounded,
                                    size: 28,
                                    color: _role == UserRole.teacher
                                        ? const Color(0xFF8B5CF6)
                                        : (isDark
                                              ? Colors.white54
                                              : ClayTokens.secondaryText),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Teacher',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: _role == UserRole.teacher
                                          ? const Color(0xFF8B5CF6)
                                          : (isDark
                                                ? Colors.white70
                                                : ClayTokens.darkInk),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Manage & grade',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white38
                                          : ClayTokens.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Full Name Field
                      ClayTextField(
                        controller: _nameController,
                        labelText: 'Full Name',
                        hintText: 'e.g. Alex Morgan',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        textInputAction: TextInputAction.next,
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Please enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Email Field
                      ClayTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        hintText: 'e.g. alex@example.com',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your email address';
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password Field
                      ClayTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: 'At least 6 characters',
                        obscureText: _obscure,
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (val) => (val == null || val.length < 6)
                            ? 'Password must be at least 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Confirm Password Field
                      ClayTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        obscureText: _obscure,
                        prefixIcon: const Icon(
                          Icons.lock_reset_rounded,
                          size: 20,
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (val != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
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
                                        fontSize: 12,
                                        color: Colors.redAccent,
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
                                  label: const Text('Retry Registration'),
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
                      ],
                      const SizedBox(height: 24),

                      // Submit Button
                      ClayButton(
                        isFullWidth: true,
                        isLoading: _busy,
                        onPressed: _busy ? null : _submit,
                        icon: Icons.check_circle_outline_rounded,
                        child: Text(
                          _role == UserRole.teacher
                              ? 'Register as Teacher'
                              : 'Register as Student',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sign up with Google
                      const GoogleSignInButton(text: 'Sign up with Google'),
                      const SizedBox(height: 16),

                      // Switch to Login
                      Center(
                        child: TextButton(
                          onPressed: () => context.push('/login'),
                          child: const Text('Already have an account? Sign In'),
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
