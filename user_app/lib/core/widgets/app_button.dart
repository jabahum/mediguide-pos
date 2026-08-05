import 'package:flutter/material.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/loading.dart';

/// A reusable button component that wraps Flutter's existing buttons with loading capability
class AppButton extends StatelessWidget {
  /// The text to display on the button
  final String text;

  /// The callback function when the button is pressed
  final VoidCallback? onPressed;

  /// Whether the button is in loading state
  final bool isLoading;

  /// The loading text to display when loading
  final String? loadingText;

  /// Optional icon to display before text
  final IconData? icon;

  /// Optional trailing icon to display after text
  final IconData? trailingIcon;

  /// Button style - uses existing Flutter button styles
  final ButtonStyle? style;

  /// Button width - null for natural width, double.infinity for full width
  final double? width;

  /// Button height
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.loadingText,
    this.icon,
    this.trailingIcon,
    this.style,
    this.width,
    this.height = 52.0,
  });

  /// Large elevated button - commonly used for primary actions
  const AppButton.large({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.loadingText,
    this.icon,
    this.trailingIcon,
    this.style,
    this.width,
  }) : height = 52.0;

  /// Medium elevated button
  const AppButton.medium({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.loadingText,
    this.icon,
    this.trailingIcon,
    this.style,
    this.width,
  }) : height = 44.0;

  /// Small elevated button
  const AppButton.small({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.loadingText,
    this.icon,
    this.trailingIcon,
    this.style,
    this.width,
  }) : height = 36.0;

  /// Build loading content using our Loading utility
  Widget _buildLoadingContent(ThemeData theme) {
    final loadingSize = height < 40 ? 16.0 : 20.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Loading(size: loadingSize, strokeWidth: 2.0),
        if (loadingText != null) ...[AppSpacing.sm.gap, Text(loadingText!)],
      ],
    );
  }

  /// Build normal content with text and icons
  Widget _buildNormalContent() {
    if (icon == null && trailingIcon == null) {
      return Text(text);
    }

    final iconSize = height < 40 ? 16.0 : 20.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: iconSize), AppSpacing.sm.gap],
        Text(text),
        if (trailingIcon != null) ...[
          AppSpacing.sm.gap,
          Icon(trailingIcon, size: iconSize),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveOnPressed = isLoading ? null : onPressed;

    // Build the content
    final content = isLoading
        ? _buildLoadingContent(theme)
        : _buildNormalContent();

    // Use ElevatedButton as default with proper styling
    Widget button = ElevatedButton(
      onPressed: effectiveOnPressed,
      style:
          style?.copyWith(
            minimumSize: WidgetStateProperty.all(Size(0, height)),
          ) ??
          ElevatedButton.styleFrom(minimumSize: Size(0, height)),
      child: content,
    );

    return width != null ? SizedBox(width: width, child: button) : button;
  }
}

/// Static factory methods for different button variants
class AppButtonVariants {
  /// Create an outlined button variant
  static Widget outlined({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    String? loadingText,
    IconData? icon,
    IconData? trailingIcon,
    double? width,
    double height = 52.0,
    ButtonStyle? style,
  }) {
    return _TypedAppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      loadingText: loadingText,
      icon: icon,
      trailingIcon: trailingIcon,
      width: width,
      height: height,
      buttonType: _ButtonType.outlined,
      style: style,
    );
  }

  /// Create a text button variant
  static Widget textButton({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    String? loadingText,
    IconData? icon,
    IconData? trailingIcon,
    double? width,
    double height = 52.0,
    ButtonStyle? style,
  }) {
    return _TypedAppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      loadingText: loadingText,
      icon: icon,
      trailingIcon: trailingIcon,
      width: width,
      height: height,
      buttonType: _ButtonType.text,
      style: style,
    );
  }

  /// Create a filled button variant
  static Widget filled({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    String? loadingText,
    IconData? icon,
    IconData? trailingIcon,
    double? width,
    double height = 52.0,
    ButtonStyle? style,
  }) {
    return _TypedAppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      loadingText: loadingText,
      icon: icon,
      trailingIcon: trailingIcon,
      width: width,
      height: height,
      buttonType: _ButtonType.filled,
      style: style,
    );
  }
}

enum _ButtonType {
  elevated(label: 'Elevated'),
  outlined(label: 'Outlined'),
  text(label: 'Text'),
  filled(label: 'Filled');

  const _ButtonType({required this.label});

  final String label;
}

class _TypedAppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingText;
  final IconData? icon;
  final IconData? trailingIcon;
  final ButtonStyle? style;
  final double? width;
  final double height;
  final _ButtonType buttonType;

  const _TypedAppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.loadingText,
    this.icon,
    this.trailingIcon,
    this.style,
    this.width,
    this.height = 52.0,
    required this.buttonType,
  });

  /// Build loading content using our Loading utility
  Widget _buildLoadingContent(ThemeData theme) {
    final loadingSize = height < 40 ? 16.0 : 20.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Loading(size: loadingSize, strokeWidth: 2.0),
        if (loadingText != null) ...[AppSpacing.sm.gap, Text(loadingText!)],
      ],
    );
  }

  /// Build normal content with text and icons
  Widget _buildNormalContent() {
    if (icon == null && trailingIcon == null) {
      return Text(text);
    }

    final iconSize = height < 40 ? 16.0 : 20.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: iconSize), AppSpacing.sm.gap],
        Text(text),
        if (trailingIcon != null) ...[
          AppSpacing.sm.gap,
          Icon(trailingIcon, size: iconSize),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveOnPressed = isLoading ? null : onPressed;

    final content = isLoading
        ? _buildLoadingContent(theme)
        : _buildNormalContent();

    Widget button;

    switch (buttonType) {
      case _ButtonType.elevated:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: _getButtonStyle(),
          child: content,
        );
        break;
      case _ButtonType.outlined:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: _getButtonStyle(),
          child: content,
        );
        break;
      case _ButtonType.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: _getButtonStyle(),
          child: content,
        );
        break;
      case _ButtonType.filled:
        button = FilledButton(
          onPressed: effectiveOnPressed,
          style: _getButtonStyle(),
          child: content,
        );
        break;
    }

    return width != null ? SizedBox(width: width, child: button) : button;
  }

  ButtonStyle? _getButtonStyle() {
    final baseStyle = switch (buttonType) {
      _ButtonType.elevated => ElevatedButton.styleFrom(
        minimumSize: Size(0, height),
      ),
      _ButtonType.outlined => OutlinedButton.styleFrom(
        minimumSize: Size(0, height),
      ),
      _ButtonType.text => TextButton.styleFrom(minimumSize: Size(0, height)),
      _ButtonType.filled => FilledButton.styleFrom(
        minimumSize: Size(0, height),
      ),
    };

    return style != null ? baseStyle.merge(style) : baseStyle;
  }
}
