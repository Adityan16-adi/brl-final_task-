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
  final _teacherKeyController = TextEditingController();

  UserRole _role = UserRole.student;
  bool _busy = false;
  bool _obscure = true;
  bool _obscureTeacherKey = true;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _teacherKeyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate() || _busy) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (_role == UserRole.teacher && _teacherKeyController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Teacher invite key is required for teacher registration.');
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final teacherCode = _role == UserRole.teacher ? _teacherKeyController.text.trim() : null;
      await repo.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
        teacherCode: teacherCode,
      );

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        final rawMsg = e.toString().toLowerCase();
        if (_role == UserRole.teacher &&
            (rawMsg.contains('teacher') ||
             rawMsg.contains('provisioning') ||
             rawMsg.contains('invite') ||
             rawMsg.contains('403') ||
             rawMsg.contains('400'))) {
          setState(() => _errorMessage = 'Invalid teacher invite key. Contact your administrator.');
        } else {
          setState(() => _errorMessage = ErrorMessageHelper.format(e));
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo & Branding
                      const Center(
                        child: BrandLogo(
                          size: 54,
                          useMarkOnly: true,
                          onCard: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        AppBranding.appName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        AppBranding.tagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ClayTokens.pragtiOrange,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Single, clean heading
                      Text(
                        'Create your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : ClayTokens.navy,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Role Picker (Two large tappable cards)
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
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => setState(() => _role = UserRole.student),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _role == UserRole.student
                                      ? (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF))
                                      : (isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _role == UserRole.student
                                        ? ClayTokens.brightBlue
                                        : (isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                                    width: _role == UserRole.student ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.school_rounded,
                                      size: 26,
                                      color: _role == UserRole.student
                                          ? ClayTokens.brightBlue
                                          : (isDark ? Colors.white54 : ClayTokens.secondaryText),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Student',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: _role == UserRole.student
                                            ? ClayTokens.brightBlue
                                            : (isDark ? Colors.white70 : ClayTokens.darkInk),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Join & submit work',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white38 : ClayTokens.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => setState(() => _role = UserRole.teacher),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _role == UserRole.teacher
                                      ? (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF))
                                      : (isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _role == UserRole.teacher
                                        ? ClayTokens.brightBlue
                                        : (isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                                    width: _role == UserRole.teacher ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.co_present_rounded,
                                      size: 26,
                                      color: _role == UserRole.teacher
                                          ? ClayTokens.brightBlue
                                          : (isDark ? Colors.white54 : ClayTokens.secondaryText),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Teacher',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: _role == UserRole.teacher
                                            ? ClayTokens.brightBlue
                                            : (isDark ? Colors.white70 : ClayTokens.darkInk),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Manage & grade',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white38 : ClayTokens.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_role == UserRole.teacher) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 6),
                              child: Text(
                                'Teacher invite key',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : ClayTokens.darkInk,
                                ),
                              ),
                            ),
                            TextFormField(
                              key: const Key('teacher_invite_key_field'),
                              controller: _teacherKeyController,
                              obscureText: _obscureTeacherKey,
                              textInputAction: TextInputAction.next,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : ClayTokens.darkInk,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter teacher invite key',
                                helperText: 'Configured in TEACHER_INVITE_KEY on the server',
                                helperStyle: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : ClayTokens.secondaryText,
                                ),
                                prefixIcon: const Icon(Icons.key_rounded, size: 20),
                                suffixIcon: IconButton(
                                  tooltip: _obscureTeacherKey ? 'Show key' : 'Hide key',
                                  icon: Icon(
                                    _obscureTeacherKey ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () => setState(() => _obscureTeacherKey = !_obscureTeacherKey),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                filled: true,
                                fillColor: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: ClayTokens.brightBlue, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                ),
                              ),
                              validator: (val) {
                                if (_role == UserRole.teacher && (val == null || val.trim().isEmpty)) {
                                  return 'Teacher invite key is required';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Full Name Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 6),
                            child: Text(
                              'Full Name',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : ClayTokens.darkInk,
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : ClayTokens.darkInk,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. Alex Morgan',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : ClayTokens.secondaryText,
                              ),
                              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              filled: true,
                              fillColor: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: ClayTokens.brightBlue, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                              ),
                            ),
                            validator: (val) => (val == null || val.trim().isEmpty)
                                ? 'Please enter your full name'
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Email Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 6),
                            child: Text(
                              'Email Address',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : ClayTokens.darkInk,
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : ClayTokens.darkInk,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. alex@example.com',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : ClayTokens.secondaryText,
                              ),
                              prefixIcon: const Icon(Icons.email_outlined, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              filled: true,
                              fillColor: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: ClayTokens.brightBlue, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                              ),
                            ),
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
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 6),
                            child: Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : ClayTokens.darkInk,
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : ClayTokens.darkInk,
                            ),
                            decoration: InputDecoration(
                              hintText: 'At least 6 characters',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : ClayTokens.secondaryText,
                              ),
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                tooltip: _obscure ? 'Show password' : 'Hide password',
                                icon: Icon(
                                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 18,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              filled: true,
                              fillColor: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: ClayTokens.brightBlue, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                              ),
                            ),
                            validator: (val) => (val == null || val.length < 6)
                                ? 'Password must be at least 6 characters'
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Confirm Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 6),
                            child: Text(
                              'Confirm Password',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : ClayTokens.darkInk,
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : ClayTokens.darkInk,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Re-enter your password',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : ClayTokens.secondaryText,
                              ),
                              prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              filled: true,
                              fillColor: isDark ? ClayTokens.darkCard : const Color(0xFFF8FAFC),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: ClayTokens.brightBlue, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                              ),
                            ),
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
                        ],
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF421D24)
                                : const Color(0xFFFFECEE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.5),
                              width: 1,
                            ),
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
                      const SizedBox(height: 20),

                      // Submit Primary Button: Solid blue fill, white text, 50px high, full width
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _busy ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ClayTokens.brightBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _role == UserRole.teacher
                                      ? 'Register as Teacher'
                                      : 'Register as Student',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subtle "or" divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                              height: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'or',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : ClayTokens.secondaryText,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                              height: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Sign up with Google
                      const GoogleSignInButton(text: 'Sign up with Google'),
                      const SizedBox(height: 16),

                      // Switch to Login
                      Center(
                        child: TextButton(
                          onPressed: () => context.push('/login'),
                          child: Text.rich(
                            TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : ClayTokens.secondaryText,
                                fontSize: 13,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Sign In',
                                  style: TextStyle(
                                    color: ClayTokens.brightBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }
}
