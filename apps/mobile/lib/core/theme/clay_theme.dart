import 'package:flutter/material.dart';

/// Claymorphism Design System Tokens and Reusable Components
///
/// Features soft bevels, multi-layer ambient highlights and drop shadows,
/// tactile spring-like buttons, and gentle color gradients.
class ClayTokens {
  ClayTokens._();

  // Core Claymorphism Color Palette
  static const Color deepIndigo = Color(0xFF5146D8);
  static const Color softLavender = Color(0xFFE9E5FF);
  static const Color warmCream = Color(0xFFFAF7F0);
  static const Color mint = Color(0xFFD8F4E7);
  static const Color mintDark = Color(0xFF0F766E);
  static const Color softPeach = Color(0xFFFFE4D6);
  static const Color peachDark = Color(0xFFC2410C);
  static const Color skyBlue = Color(0xFFDCEEFF);
  static const Color skyDark = Color(0xFF0369A1);
  static const Color darkInk = Color(0xFF25243A);
  static const Color secondaryText = Color(0xFF77758B);

  // Background and Surface Tones
  static const Color lightBg = Color(0xFFF3F2F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkBg = Color(0xFF141322);
  static const Color darkSurface = Color(0xFF1F1D33);
  static const Color darkCard = Color(0xFF272540);

  // Corner Radii
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 18.0;
  static const double radiusLarge = 24.0;
  static const double radiusPill = 999.0;

  /// Generates the distinctive dual-layer Claymorphic box shadows:
  /// 1. Top-left light highlight (reflects ambient overhead light)
  /// 2. Bottom-right soft dark shadow (creates elevated clay cushion feel)
  static List<BoxShadow> clayShadows({
    required bool isDark,
    double depth = 6.0,
    double spread = 0.0,
    Color? highlightColor,
    Color? shadowColor,
  }) {
    final topHighlight =
        highlightColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.95));

    final bottomShadow =
        shadowColor ??
        (isDark
            ? Colors.black.withValues(alpha: 0.45)
            : const Color(0xFF25243A).withValues(alpha: 0.10));

    return [
      BoxShadow(
        color: topHighlight,
        offset: Offset(-depth * 0.6, -depth * 0.6),
        blurRadius: depth * 1.2,
        spreadRadius: spread,
      ),
      BoxShadow(
        color: bottomShadow,
        offset: Offset(depth * 0.7, depth * 0.7),
        blurRadius: depth * 1.6,
        spreadRadius: spread,
      ),
    ];
  }

  /// Recessed/concave shadow for pressed state or input wells
  static List<BoxShadow> insetShadows({required bool isDark}) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : const Color(0xFF25243A).withValues(alpha: 0.08),
        offset: const Offset(2, 2),
        blurRadius: 4,
      ),
      BoxShadow(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.8),
        offset: const Offset(-2, -2),
        blurRadius: 4,
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
    final buttonColor = widget.color ?? ClayTokens.deepIndigo;
    final isPrimaryIndigo =
        buttonColor == ClayTokens.deepIndigo && widget.gradient == null;

    final defaultGradient = isPrimaryIndigo
        ? const LinearGradient(
            colors: [Color(0xFF6356F5), Color(0xFF473BB8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final effectiveGradient = widget.gradient ?? defaultGradient;
    final depth = _isPressed ? 1.5 : widget.depth;

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.isFullWidth ? double.infinity : null,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: effectiveGradient == null ? buttonColor : null,
          gradient: effectiveGradient,
          borderRadius: effectiveRadius,
          boxShadow: _isPressed
              ? ClayTokens.insetShadows(isDark: isDark)
              : ClayTokens.clayShadows(
                  isDark: isDark,
                  depth: depth,
                  shadowColor: isPrimaryIndigo
                      ? const Color(0xFF32279B).withValues(alpha: 0.35)
                      : null,
                ),
        ),
        child: content,
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
            borderRadius: BorderRadius.circular(ClayTokens.radiusMedium),
            boxShadow: ClayTokens.insetShadows(isDark: isDark),
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
