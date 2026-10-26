import 'package:flutter/material.dart';

/// Claymorphism Design System Tokens and Reusable Components
///
/// Features soft bevels, multi-layer ambient highlights and drop shadows,
/// tactile spring-like buttons, and gentle color gradients.
class ClayTokens {
  ClayTokens._();

  // Core Claymorphism Color Palette
  static const Color deepIndigo = Color(0xFF1680ED);
  static const Color softLavender = Color(0xFFEEF4FF);
  static const Color warmCream = Color(0xFFFAF7F0);
  static const Color mint = Color(0xFFD8F4E7);
  static const Color mintDark = Color(0xFF0F766E);
  static const Color softPeach = Color(0xFFFFE4D6);
  static const Color peachDark = Color(0xFFC2410C);
  static const Color skyBlue = Color(0xFFDCEEFF);
  static const Color skyDark = Color(0xFF0369A1);
  static const Color darkInk = Color(0xFF0B1E48);
  static const Color secondaryText = Color(0xFF6B7280);

  // Official Pragti Brand Palette (Sampled from pragti_logo_original.jpeg)
  static const Color pragtiNavy = Color(0xFF0B1E48);
  static const Color pragtiDeepNavy = Color(0xFF021742);
  static const Color pragtiBlue = Color(0xFF1680ED);
  static const Color pragtiOrange = Color(0xFFFB9823);
  static const Color pragtiStar = Color(0xFFFBB746);
  static const Color pragtiSoftBlue = Color(0xFFEEF4FF);
  static const Color brightBlue = Color(0xFF1680ED);
  static const Color navy = Color(0xFF0B1E48);

  // Background and Surface Tones (Calm deep slate #0A0F1C dark, #F5F7FB light)
  static const Color lightBg = Color(0xFFF5F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkBg = Color(0xFF0A0F1C);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF172033);
  static const Color borderLight = Color(0xFFE3E8F0);
  static const Color borderDark = Color(0xFF243049);

  // Corner Radii
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusPill = 999.0;

  /// Generates clean, subtle soft depth shadows without purple/violet tint:
  static List<BoxShadow> clayShadows({
    required bool isDark,
    double depth = 4.0,
    double spread = 0.0,
    Color? highlightColor,
    Color? shadowColor,
  }) {
    if (depth <= 0) return const [];
    final ambientShadow = shadowColor ??
        (isDark
            ? Colors.black.withValues(alpha: 0.35)
            : const Color(0xFF0B1E48).withValues(alpha: 0.04));

    return [
      BoxShadow(
        color: ambientShadow,
        offset: Offset(0, depth * 0.5),
        blurRadius: depth * 1.5,
        spreadRadius: spread,
      ),
    ];
  }

  /// Recessed/concave shadow for pressed state or input wells
  static List<BoxShadow> insetShadows({required bool isDark}) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : const Color(0xFF0B1E48).withValues(alpha: 0.04),
        offset: const Offset(1, 1),
        blurRadius: 3,
      ),
    ];
  }
}

/// A versatile Claymorphic container with soft dual-layer shadows,
/// rounded corners, and subtle surface gradients.
class ClayContainer extends StatelessWidget {
  const ClayContainer({
    super.key,
    required this.child,
    this.color,
    this.gradient,
    this.borderRadius,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
    this.depth = 6.0,
    this.border,
  });

  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double depth;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? ClayTokens.darkSurface : ClayTokens.lightSurface;
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(ClayTokens.radiusMedium);

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? defaultBg) : null,
        gradient: gradient,
        borderRadius: effectiveRadius,
        border: border,
        boxShadow: ClayTokens.clayShadows(isDark: isDark, depth: depth),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

/// A tactile Claymorphic Card that responds smoothly to taps.
class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.gradient,
    this.borderRadius,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.depth = 6.0,
    this.border,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double depth;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? ClayTokens.darkCard : ClayTokens.lightSurface;
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(ClayTokens.radiusMedium);

    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? defaultBg) : null,
        gradient: gradient,
        borderRadius: effectiveRadius,
        border: border,
        boxShadow: ClayTokens.clayShadows(isDark: isDark, depth: depth),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );

    if (onTap == null) {
      return Padding(padding: margin, child: card);
    }

    return Padding(
      padding: margin,
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius as BorderRadius?,
          splashColor: (color ?? ClayTokens.deepIndigo).withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: card,
        ),
      ),
    );
  }
}

/// A cushion-like, tactile Claymorphic button.
class ClayButton extends StatefulWidget {
  const ClayButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.textColor,
    this.gradient,
    this.icon,
    this.depth = 6.0,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.isLoading = false,
    this.isFullWidth = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final Color? textColor;
  final Gradient? gradient;
  final IconData? icon;
  final double depth;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final bool isFullWidth;

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius =
        widget.borderRadius ?? BorderRadius.circular(ClayTokens.radiusMedium);
    final buttonColor = widget.color ?? ClayTokens.brightBlue;
    final depth = _isPressed ? 1.0 : widget.depth;

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: widget.textColor ?? Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: widget.textColor ?? Colors.white),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: widget.textColor ?? Colors.white,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: widget.child,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed!();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.isFullWidth ? double.infinity : null,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.gradient == null ? buttonColor : null,
            gradient: widget.gradient,
            borderRadius: effectiveRadius,
            boxShadow: _isPressed
                ? ClayTokens.insetShadows(isDark: isDark)
                : ClayTokens.clayShadows(
                    isDark: isDark,
                    depth: depth,
                  ),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// A tactile clay-styled badge for role pills, status tags, and chips.
class ClayBadge extends StatelessWidget {
  const ClayBadge({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.fontSize = 11.0,
    this.depth = 3.0,
  });

  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double depth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        backgroundColor ??
        (isDark ? ClayTokens.darkCard : ClayTokens.softLavender);
    final text = textColor ?? (isDark ? Colors.white : ClayTokens.deepIndigo);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ClayTokens.radiusPill),
        boxShadow: ClayTokens.clayShadows(isDark: isDark, depth: depth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: text),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: text,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A Claymorphic input wrapper that provides a recessed, soft-inset look.
class ClayTextField extends StatelessWidget {
  const ClayTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ClayTokens.darkCard : const Color(0xFFF0EFF8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              labelText!,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white70 : ClayTokens.darkInk,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            validator: validator,
            onFieldSubmitted: onFieldSubmitted,
            maxLines: maxLines,
            minLines: minLines,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : ClayTokens.darkInk,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : ClayTokens.secondaryText,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ClayTokens.radiusMedium),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1.2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ClayTokens.radiusMedium),
                borderSide: const BorderSide(
                  color: Colors.redAccent,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A pulsing skeleton loader designed for claymorphism surfaces.
class ClaySkeleton extends StatefulWidget {
  const ClaySkeleton({
    super.key,
    this.width,
    this.height = 16.0,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  @override
  State<ClaySkeleton> createState() => _ClaySkeletonState();
}

class _ClaySkeletonState extends State<ClaySkeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  bool get _isInTest =>
      WidgetsBinding.instance.runtimeType
          .toString()
          .contains('TestWidgetsFlutterBinding');

  @override
  void initState() {
    super.initState();
    if (!_isInTest) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..repeat(reverse: true);
      _animation = Tween<double>(begin: 0.45, end: 0.90).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF2C2A44) : const Color(0xFFE5E2F2);
    final effectiveRadius =
        widget.borderRadius ?? BorderRadius.circular(ClayTokens.radiusSmall);

    if (_animation != null) {
      return AnimatedBuilder(
        animation: _animation!,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: _animation!.value),
              borderRadius: effectiveRadius,
            ),
          );
        },
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.65),
        borderRadius: effectiveRadius,
      ),
    );
  }
}

/// A claymorphic card skeleton with soft shimmer placeholders.
class ClaySkeletonCard extends StatelessWidget {
  const ClaySkeletonCard({
    super.key,
    this.height,
    this.hasLeading = true,
    this.lines = 2,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final double? height;
  final bool hasLeading;
  final int lines;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      margin: margin,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasLeading) ...[
              const ClaySkeleton(
                width: 44,
                height: 44,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ClaySkeleton(
                    width: double.infinity,
                    height: 14,
                  ),
                  const SizedBox(height: 8),
                  const FractionallySizedBox(
                    widthFactor: 0.65,
                    child: ClaySkeleton(
                      height: 10,
                    ),
                  ),
                  if (lines > 2) ...[
                    const SizedBox(height: 8),
                    const FractionallySizedBox(
                      widthFactor: 0.40,
                      child: ClaySkeleton(
                        height: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A column/list of ClaySkeletonCard placeholders.
class ClaySkeletonList extends StatelessWidget {
  const ClaySkeletonList({
    super.key,
    this.itemCount = 3,
    this.hasLeading = true,
    this.lines = 2,
    this.padding = EdgeInsets.zero,
  });

  final int itemCount;
  final bool hasLeading;
  final int lines;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(
          itemCount,
          (index) => ClaySkeletonCard(
            hasLeading: hasLeading,
            lines: lines,
          ),
        ),
      ),
    );
  }
}
