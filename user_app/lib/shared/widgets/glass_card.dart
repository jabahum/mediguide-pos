import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:user_app/core/constants/app_spacing.dart';

/// A reusable glass card component with frosted glass effect
///
/// This component provides a glassmorphism design with backdrop filter blur,
/// semi-transparent background, and subtle border for modern UI aesthetics.
class GlassCard extends StatelessWidget {
  /// The child widget to display inside the glass card
  final Widget child;

  /// The width of the glass card (null for natural width)
  final double? width;

  /// The maximum width constraint for the glass card
  final double? maxWidth;

  /// The border radius for the glass card
  final double borderRadius;

  /// The blur intensity for the backdrop filter
  final double blurIntensity;

  /// The opacity of the glass background
  final double backgroundOpacity;

  /// The opacity of the glass border
  final double borderOpacity;

  /// The width of the glass border
  final double borderWidth;

  /// The padding inside the glass card
  final EdgeInsets? padding;

  /// The base color for the glass effect (defaults to white)
  final Color? baseColor;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.maxWidth = 400,
    this.borderRadius = 20,
    this.blurIntensity = 10,
    this.backgroundOpacity = 0.05,
    this.borderOpacity = 0.2,
    this.borderWidth = 1.5,
    this.padding,
    this.baseColor,
  });

  /// Creates a glass card with default auth form styling
  const GlassCard.auth({
    super.key,
    required this.child,
    this.width,
    this.maxWidth = 400,
    EdgeInsets? padding,
    this.baseColor,
  }) : borderRadius = 20,
       blurIntensity = 10,
       backgroundOpacity = 0.05,
       borderOpacity = 0.2,
       borderWidth = 1.5,
       padding = padding ?? AppSpacing.cardPaddingLg;

  /// Creates a glass card with compact styling
  const GlassCard.compact({
    super.key,
    required this.child,
    this.width,
    this.maxWidth = 400,
    EdgeInsets? padding,
    this.baseColor,
  }) : borderRadius = 16,
       blurIntensity = 8,
       backgroundOpacity = 0.03,
       borderOpacity = 0.15,
       borderWidth = 1.0,
       padding = padding ?? AppSpacing.cardPadding;

  /// Creates a glass card with prominent styling
  const GlassCard.prominent({
    super.key,
    required this.child,
    this.width,
    this.maxWidth = 400,
    EdgeInsets? padding,
    this.baseColor,
  }) : borderRadius = 24,
       blurIntensity = 12,
       backgroundOpacity = 0.08,
       borderOpacity = 0.25,
       borderWidth = 2.0,
       padding = padding ?? AppSpacing.cardPaddingLg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use baseColor if provided, otherwise default to white
    final effectiveBaseColor = baseColor ?? Colors.white;

    // Theme-aware color selection
    final backgroundColor = effectiveBaseColor.withValues(
      alpha: isDark ? backgroundOpacity : backgroundOpacity + 0.3,
    );

    final borderColor = effectiveBaseColor.withValues(
      alpha: isDark ? borderOpacity : borderOpacity + 0.5,
    );

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      ),
    );

    // Apply width constraints
    if (width != null) {
      card = SizedBox(width: width, child: card);
    }

    if (maxWidth != null) {
      card = Container(
        width: width ?? double.infinity,
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: card,
      );
    }

    return card;
  }
}
