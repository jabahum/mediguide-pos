import 'package:flutter/material.dart';

/// A reusable loading widget with customizable circular progress indicator
class Loading extends StatelessWidget {
  /// The size of the loading indicator
  final double size;

  /// The stroke width of the circular progress indicator
  final double strokeWidth;

  /// The color of the progress indicator
  final Color? color;

  /// Optional text to display below the loading indicator
  final String? text;

  /// Text style for the loading text
  final TextStyle? textStyle;

  /// Spacing between indicator and text
  final double spacing;

  const Loading({
    super.key,
    this.size = 24.0,
    this.strokeWidth = 2.0,
    this.color,
    this.text,
    this.textStyle,
    this.spacing = 8.0,
  });

  /// Small loading indicator (16x16)
  const Loading.small({
    super.key,
    this.size = 16.0,
    this.strokeWidth = 1.5,
    this.color,
    this.text,
    this.textStyle,
    this.spacing = 6.0,
  });

  /// Medium loading indicator (24x24) - default
  const Loading.medium({
    super.key,
    this.size = 24.0,
    this.strokeWidth = 2.0,
    this.color,
    this.text,
    this.textStyle,
    this.spacing = 8.0,
  });

  /// Large loading indicator (32x32)
  const Loading.large({
    super.key,
    this.size = 32.0,
    this.strokeWidth = 2.5,
    this.color,
    this.text,
    this.textStyle,
    this.spacing = 12.0,
  });

  /// Extra large loading indicator (48x48)
  const Loading.xlarge({
    super.key,
    this.size = 48.0,
    this.strokeWidth = 3.0,
    this.color,
    this.text,
    this.textStyle,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          ),
        ),
        if (text != null) ...[
          SizedBox(height: spacing),
          Text(
            text!,
            style:
                textStyle ??
                theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// A centered loading widget that takes up available space
class CenteredLoading extends StatelessWidget {
  /// The loading widget to center
  final Loading loading;

  const CenteredLoading({super.key, required this.loading});

  /// Centered small loading
  const CenteredLoading.small({super.key, String? text, Color? color})
    : loading = const Loading.small();

  /// Centered medium loading (default)
  const CenteredLoading.medium({super.key, String? text, Color? color})
    : loading = const Loading.medium();

  /// Centered large loading
  const CenteredLoading.large({super.key, String? text, Color? color})
    : loading = const Loading.large();

  @override
  Widget build(BuildContext context) {
    return Center(child: loading);
  }
}

/// Extension methods for quick loading widgets
extension LoadingExtension on Widget {
  /// Wrap this widget with a loading overlay
  Widget withLoading({
    required bool isLoading,
    Loading loading = const Loading.medium(),
    Color? overlayColor,
  }) {
    return Stack(
      children: [
        this,
        if (isLoading)
          Container(
            color: overlayColor ?? Colors.black.withValues(alpha: 0.3),
            child: Center(child: loading),
          ),
      ],
    );
  }
}
