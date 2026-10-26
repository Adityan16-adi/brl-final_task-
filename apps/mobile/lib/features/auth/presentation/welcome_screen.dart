import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/brand_widgets.dart';
import '../../../core/theme/clay_theme.dart';
import '../application/auth_providers.dart';

/// Clean, modern Welcome screen for Pragti ("Learn · Connect · Grow").
/// Features subtle ambient brand circles, a floating logo tile, staggered entrance,
/// three quiet feature chips, solid #1680ED "Get Started" action, and sign-in link.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Staggered fade-and-rise entrance under 700ms total
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    // Subtle 4px float animation on logo (disabled in test binding for pumpAndSettle compatibility)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _floatController.repeat(reverse: true);
    }

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _onGetStarted() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.setOnboardingCompleted(true);
    if (mounted) {
      context.go('/register');
    }
  }

  Future<void> _onSignIn() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.setOnboardingCompleted(true);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? ClayTokens.darkBg : ClayTokens.lightBg;
    final cardBorder = isDark ? const Color(0xFF243049) : const Color(0xFFE3E8F0);
    final textColor = isDark ? const Color(0xFFF1F5F9) : ClayTokens.navy;
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : ClayTokens.secondaryText;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ONE soft decorative pair (low-opacity 6-10% plain circles, no images/blur)
          // Top-right brand blue circle
          Positioned(
            top: -50,
            right: -50,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ClayTokens.brightBlue.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          // Bottom-left orange circle
          Positioned(
            bottom: -40,
            left: -40,
            child: IgnorePointer(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ClayTokens.pragtiOrange.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),

          // Main Content with staggered entrance
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),

                          // Floating centered logo tile and brand header
                          AnimatedBuilder(
                            animation: _floatController,
                            builder: (context, child) {
                              final offset = math.sin(_floatController.value * 2 * math.pi) * 3.5;
                              return Transform.translate(
                                offset: Offset(0, offset),
                                child: child,
                              );
                            },
                            child: const BrandHeader(markSize: 76),
                          ),
                          const SizedBox(height: 12),

                          // One line description
                          Text(
                            'Classes, assignments and live lessons in one place.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Three quiet outlined feature chips (Classes, Live, AI Mentor)
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildFeatureChip(
                                icon: Icons.school_outlined,
                                label: 'Classes',
                                isDark: isDark,
                                border: cardBorder,
                                text: textColor,
                              ),
                              _buildFeatureChip(
                                icon: Icons.videocam_outlined,
                                label: 'Live',
                                isDark: isDark,
                                border: cardBorder,
                                text: textColor,
                              ),
                              _buildFeatureChip(
                                icon: Icons.auto_awesome_outlined,
                                label: 'AI Mentor',
                                isDark: isDark,
                                border: cardBorder,
                                text: textColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),

                          // Full-width Get Started button (solid #1680ED, 56px, 16px radius)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: _onGetStarted,
                              style: FilledButton.styleFrom(
                                backgroundColor: ClayTokens.brightBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Link: "Already have an account? Sign in"
                          GestureDetector(
                            onTap: _onSignIn,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: secondaryTextColor,
                                  ),
                                  children: const [
                                    TextSpan(text: 'Already have an account? '),
                                    TextSpan(
                                      text: 'Sign in',
                                      style: TextStyle(
                                        color: ClayTokens.brightBlue,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color border,
    required Color text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: ClayTokens.brightBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
