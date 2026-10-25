import 'package:flutter/material.dart';

import '../theme/clay_theme.dart';
import 'app_branding.dart';

/// Reusable brand logo widget adhering to the Pragti Claymorphic design system.
///
/// In dark mode, it renders the logo inside a subtle light clay card so that the
/// navy graduate figure and dark elements remain vivid and clearly legible,
/// eliminating unstyled raw white squares.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 64.0,
    this.useMarkOnly = false,
    this.onCard = true,
    this.borderRadius,
  });

  /// The width/height of the logo asset.
  final double size;

  /// Whether to show only the graduate/books/star mark or the full logo.
  final bool useMarkOnly;

  /// Whether to wrap the logo in a soft clay container.
  final bool onCard;

  /// Optional override for border radius.
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assetPath = useMarkOnly ? AppBranding.mark : AppBranding.logoTransparent;

    final imageWidget = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback icon if asset is loading or missing
        return Icon(
          Icons.school_rounded,
          size: size * 0.7,
          color: ClayTokens.pragtiBlue,
        );
      },
    );

    if (!onCard) {
      return imageWidget;
    }

    final cardRadius = borderRadius ?? BorderRadius.circular(size * 0.28);

    // Clay styled card backing
    return ClayContainer(
      width: size + 20,
      height: size + 20,
      depth: 5,
      color: isDark ? const Color(0xFFF8FAFC) : Colors.white,
      borderRadius: cardRadius,
      padding: const EdgeInsets.all(10),
      child: Center(child: imageWidget),
    );
  }
}

/// Comprehensive Brand Header showing the Mark, App Name, and Tagline.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    this.markSize = 64.0,
    this.showTagline = true,
    this.alignment = CrossAxisAlignment.center,
  });

  final double markSize;
  final bool showTagline;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        BrandLogo(
          size: markSize,
          useMarkOnly: true,
          onCard: true,
        ),
        const SizedBox(height: 14),
        Text(
          AppBranding.appName,
          textAlign: alignment == CrossAxisAlignment.center
              ? TextAlign.center
              : TextAlign.start,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : ClayTokens.pragtiDeepNavy,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            AppBranding.tagline,
            textAlign: alignment == CrossAxisAlignment.center
                ? TextAlign.center
                : TextAlign.start,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: ClayTokens.pragtiOrange,
            ),
          ),
        ],
      ],
    );
  }
}
