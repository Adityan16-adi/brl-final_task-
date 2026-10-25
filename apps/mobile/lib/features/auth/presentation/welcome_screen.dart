import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/theme/clay_theme.dart';
import '../application/auth_providers.dart';
import '../domain/auth_repository.dart';
import 'widgets/google_sign_in_handler.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _busy = false;

  Future<void> _quickLogin(String email) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.setOnboardingCompleted(true);
      final role =
          email.contains('teacher') ? UserRole.teacher : UserRole.student;
      await repo.signInDemo(role: role);
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Demo session failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Claymorphic Badge
                  Center(
                    child: ClayContainer(
                      width: 76,
                      height: 76,
                      depth: 7,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B5EFF), Color(0xFF4335C9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      child: const Center(
                        child: Icon(
                          Icons.school_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Brand Title & Tagline
                  Text(
                    AppBranding.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      color: isDark ? Colors.white : ClayTokens.darkInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Empowering students & educators with collaborative virtual classrooms, automated grading, and an intelligent AI mentor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white70 : ClayTokens.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Demo Evaluation Shortcuts
                  ClayCard(
                    depth: 4,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    color: isDark
                        ? ClayTokens.darkCard
                        : const Color(0xFFEDEAF8),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 16,
                              color: ClayTokens.deepIndigo,
                            ),
                            SizedBox(width: 6),
                            Flexible(
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
                                size: 15,
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
                                size: 15,
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

                  // Call To Actions
                  ClayButton(
                    isFullWidth: true,
                    onPressed: _busy
                        ? null
                        : () async {
                            await ref
                                .read(authRepositoryProvider)
                                .setOnboardingCompleted(true);
                            if (context.mounted) {
                              context.push('/register');
                            }
                          },
                    icon: Icons.arrow_forward_rounded,
                    child: const Text('Get Started — Create Account'),
                  ),
                  const SizedBox(height: 12),

                  ClayButton(
                    isFullWidth: true,
                    color: isDark ? ClayTokens.darkSurface : Colors.white,
                    textColor: isDark ? Colors.white : ClayTokens.darkInk,
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF292742), const Color(0xFF1E1C30)]
                          : [Colors.white, const Color(0xFFF7F6FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onPressed: _busy
                        ? null
                        : () async {
                            await ref
                                .read(authRepositoryProvider)
                                .setOnboardingCompleted(true);
                            if (context.mounted) {
                              context.push('/login');
                            }
                          },
                    icon: Icons.login_rounded,
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(height: 12),

                  // Sign in with Google
                  const GoogleSignInButton(),
                  const SizedBox(height: 12),

                  // Explicit Clearly Labelled Demo Mode Button
                  ClayButton(
                    isFullWidth: true,
                    color: isDark ? const Color(0xFF382F18) : const Color(0xFFFEF3C7),
                    textColor: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF3D3216), const Color(0xFF29210B)]
                          : [const Color(0xFFFEF9C3), const Color(0xFFFDE68A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onPressed: _busy
                        ? null
                        : () => _quickLogin('student@demo.com'),
                    icon: Icons.science_outlined,
                    child: const Text('Explore in Demo Mode (Offline)'),
                  ),
                  const SizedBox(height: 24),

                  // Feature Cards Carousel / Highlights
                  ClayCard(
                    padding: const EdgeInsets.all(14),
                    depth: 4,
                    child: Row(
                      children: [
                        ClayContainer(
                          width: 44,
                          height: 44,
                          depth: 3,
                          color: ClayTokens.softLavender,
                          borderRadius: BorderRadius.circular(14),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: ClayTokens.deepIndigo,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Role-Secured Classrooms',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Teachers manage rosters & share join codes; students enroll in one click.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ClayTokens.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  ClayCard(
                    padding: const EdgeInsets.all(14),
                    depth: 4,
                    child: Row(
                      children: [
                        ClayContainer(
                          width: 44,
                          height: 44,
                          depth: 3,
                          color: ClayTokens.mint,
                          borderRadius: BorderRadius.circular(14),
                          child: const Icon(
                            Icons.assignment_turned_in_rounded,
                            color: ClayTokens.mintDark,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assignments & Direct Feedback',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Submit work easily, receive grades with personalized remarks, track progress.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ClayTokens.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  ClayCard(
                    padding: const EdgeInsets.all(14),
                    depth: 4,
                    child: Row(
                      children: [
                        ClayContainer(
                          width: 44,
                          height: 44,
                          depth: 3,
                          color: ClayTokens.softPeach,
                          borderRadius: BorderRadius.circular(14),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: ClayTokens.peachDark,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '24/7 AI Mentor Assistant',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Ask difficult study questions, generate study plans, and master concepts.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ClayTokens.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
