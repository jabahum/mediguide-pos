import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class Extensions {}

extension StringLog on String {
  void printStr() {
    if (kDebugMode) {
      debugPrint(this);
    }
  }

  void logStr({String? name, Object? error}) {
    return log(this, name: name ?? "", error: error);
  }
}

/// Extension on num to create Gap widgets efficiently
/// Usage: AppSpacing.md.gap, AppSpacing.sm.hGap, etc.
extension NumToGap on num {
  /// Create a vertical/horizontal Gap widget from a number
  /// Usage: AppSpacing.md.gap
  Widget get gap => Gap(toDouble());

  /// Create a horizontal Gap widget from a number
  /// Usage: AppSpacing.sm.hGap (same as gap, but more explicit for horizontal spacing)
  Widget get hGap => Gap(toDouble());

  /// Create a vertical Gap widget from a number
  /// Usage: AppSpacing.lg.vGap (same as gap, but more explicit for vertical spacing)
  Widget get vGap => Gap(toDouble());
}

/// Extension on num to create EdgeInsets (padding/margin) efficiently
/// Usage: AppSpacing.md.padding, AppSpacing.sm.hPadding, etc.
extension NumToPadding on num {
  /// Create EdgeInsets.all() from a number
  /// Usage: AppSpacing.md.padding
  EdgeInsets get padding => EdgeInsets.all(toDouble());

  /// Create horizontal padding from a number
  /// Usage: AppSpacing.sm.hPadding
  EdgeInsets get hPadding => EdgeInsets.symmetric(horizontal: toDouble());

  /// Create vertical padding from a number
  /// Usage: AppSpacing.md.vPadding
  EdgeInsets get vPadding => EdgeInsets.symmetric(vertical: toDouble());

  /// Create top padding from a number
  /// Usage: AppSpacing.sm.tPadding
  EdgeInsets get tPadding => EdgeInsets.only(top: toDouble());

  /// Create bottom padding from a number
  /// Usage: AppSpacing.sm.bPadding
  EdgeInsets get bPadding => EdgeInsets.only(bottom: toDouble());

  /// Create left padding from a number
  /// Usage: AppSpacing.md.lPadding
  EdgeInsets get lPadding => EdgeInsets.only(left: toDouble());

  /// Create right padding from a number
  /// Usage: AppSpacing.sm.rPadding
  EdgeInsets get rPadding => EdgeInsets.only(right: toDouble());

  /// Create padding with top and bottom values
  /// Usage: AppSpacing.md.tbPadding
  EdgeInsets get tbPadding => EdgeInsets.symmetric(vertical: toDouble());

  /// Create padding with left and right values
  /// Usage: AppSpacing.lg.lrPadding
  EdgeInsets get lrPadding => EdgeInsets.symmetric(horizontal: toDouble());
}

/// Extension on String? to convert hex color strings to Flutter Color objects
/// Supports various hex formats: #RGB, #RRGGBB, #AARRGGBB, RGB, RRGGBB, AARRGGBB
/// Usage: '#FF0000'.toColor(), 'FF0000'.toColor(), '#F00'.toColor()
extension StringColorExtension on String? {
  /// Regular expression for validating hex color strings
  /// Supports: #RGB, #RRGGBB, #AARRGGBB, RGB, RRGGBB, AARRGGBB
  static final RegExp _hexColorRegex = RegExp(
    r'^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8}|[A-Fa-f0-9]{3})$',
  );

  /// Converts a hex color string to a Flutter Color object
  ///
  /// Supported formats:
  /// - #RGB (3 digits) -> expanded to #RRGGBB
  /// - #RRGGBB (6 digits) -> RGB with full opacity
  /// - #AARRGGBB (8 digits) -> ARGB with alpha
  /// - Same formats without # prefix
  ///
  /// Examples:
  /// ```dart
  /// '#FF0000'.toColor()    // Red
  /// 'FF0000'.toColor()     // Red (without #)
  /// '#F00'.toColor()       // Red (short form)
  /// '#80FF0000'.toColor()  // Semi-transparent red
  /// ```
  ///
  /// Returns [Colors.transparent] for null or invalid input
  Color toColor() {
    if (this == null || this!.isEmpty) {
      return Colors.transparent;
    }

    final cleanHex = this!.replaceFirst('#', '').toUpperCase();

    if (!_hexColorRegex.hasMatch('#$cleanHex')) {
      return Colors.transparent;
    }

    try {
      String processedHex = cleanHex;

      // Handle 3-digit RGB format (#RGB -> #RRGGBB)
      if (processedHex.length == 3) {
        processedHex = processedHex.split('').map((c) => c + c).join();
      }

      // Add full opacity for 6-digit format (RRGGBB -> FFRRGGBB)
      if (processedHex.length == 6) {
        processedHex = 'FF$processedHex';
      }

      // Parse as ARGB hex value
      final colorValue = int.parse(processedHex, radix: 16);
      return Color(colorValue);
    } catch (e) {
      return Colors.transparent;
    }
  }

  /// Safely converts a hex color string to a Flutter Color object
  ///
  /// Returns null for invalid or null input instead of Colors.transparent
  ///
  /// Examples:
  /// ```dart
  /// '#FF0000'.toColorOrNull()  // Red
  /// 'invalid'.toColorOrNull()  // null
  /// null.toColorOrNull()       // null
  /// ```
  Color? toColorOrNull() {
    if (this == null || this!.isEmpty) {
      return null;
    }

    final cleanHex = this!.replaceFirst('#', '').toUpperCase();

    if (!_hexColorRegex.hasMatch('#$cleanHex')) {
      return null;
    }

    try {
      String processedHex = cleanHex;

      // Handle 3-digit RGB format
      if (processedHex.length == 3) {
        processedHex = processedHex.split('').map((c) => c + c).join();
      }

      // Add full opacity for 6-digit format
      if (processedHex.length == 6) {
        processedHex = 'FF$processedHex';
      }

      final colorValue = int.parse(processedHex, radix: 16);
      return Color(colorValue);
    } catch (e) {
      return null;
    }
  }

  /// Converts a hex color string to a Flutter Color object with specified opacity
  ///
  /// The opacity parameter should be between 0.0 (transparent) and 1.0 (opaque)
  ///
  /// Examples:
  /// ```dart
  /// '#FF0000'.toColorWithOpacity(0.5)  // Semi-transparent red
  /// '#00FF00'.toColorWithOpacity(0.8)  // 80% opaque green
  /// ```
  ///
  /// Returns [Colors.transparent] for null or invalid input
  Color toColorWithOpacity(double opacity) {
    final baseColor = toColor();
    if (baseColor == Colors.transparent) {
      return Colors.transparent;
    }
    return baseColor.withValues(alpha: opacity.clamp(0.0, 1.0));
  }

  /// Checks if the string is a valid hex color format
  ///
  /// Supports: #RGB, #RRGGBB, #AARRGGBB, RGB, RRGGBB, AARRGGBB
  ///
  /// Examples:
  /// ```dart
  /// '#FF0000'.isValidHexColor  // true
  /// 'FF0000'.isValidHexColor   // true
  /// '#F00'.isValidHexColor     // true
  /// 'invalid'.isValidHexColor  // false
  /// null.isValidHexColor       // false
  /// ```
  bool get isValidHexColor {
    if (this == null || this!.isEmpty) {
      return false;
    }

    final cleanHex = this!.replaceFirst('#', '');
    return _hexColorRegex.hasMatch('#$cleanHex');
  }
}

/// Extension on num to create common margin EdgeInsets
/// Usage: AppSpacing.md.margin, AppSpacing.sm.hMargin, etc. (semantically the same as padding but clearer intent)
extension NumToMargin on num {
  /// Create EdgeInsets.all() from a number (for margins)
  /// Usage: AppSpacing.md.margin
  EdgeInsets get margin => EdgeInsets.all(toDouble());

  /// Create horizontal margin from a number
  /// Usage: AppSpacing.sm.hMargin
  EdgeInsets get hMargin => EdgeInsets.symmetric(horizontal: toDouble());

  /// Create vertical margin from a number
  /// Usage: AppSpacing.md.vMargin
  EdgeInsets get vMargin => EdgeInsets.symmetric(vertical: toDouble());

  /// Create top margin from a number
  /// Usage: AppSpacing.sm.tMargin
  EdgeInsets get tMargin => EdgeInsets.only(top: toDouble());

  /// Create bottom margin from a number
  /// Usage: AppSpacing.sm.bMargin
  EdgeInsets get bMargin => EdgeInsets.only(bottom: toDouble());

  /// Create left margin from a number
  /// Usage: AppSpacing.md.lMargin
  EdgeInsets get lMargin => EdgeInsets.only(left: toDouble());

  /// Create right margin from a number
  /// Usage: AppSpacing.sm.rMargin
  EdgeInsets get rMargin => EdgeInsets.only(right: toDouble());
}
