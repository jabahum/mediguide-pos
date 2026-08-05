import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// App-wide spacing constants and utilities following Material Design 4dp grid system
class AppSpacing {
  AppSpacing._();

  // Base spacing unit (4dp grid system)
  static const double _baseUnit = 4.0;

  // Static spacing constants
  /// Extra small spacing: 4px
  static const double xs = _baseUnit * 1; // 4px

  /// Small spacing: 8px
  static const double sm = _baseUnit * 2; // 8px

  /// Medium spacing: 16px (base spacing)
  static const double md = _baseUnit * 4; // 16px

  /// Large spacing: 24px
  static const double lg = _baseUnit * 6; // 24px

  /// Extra large spacing: 32px
  static const double xl = _baseUnit * 8; // 32px

  /// Extra extra large spacing: 48px
  static const double xxl = _baseUnit * 12; // 48px

  /// Massive spacing: 64px
  static const double xxxl = _baseUnit * 16; // 64px

  /// Huge spacing: 96px
  static const double xxxxl = _baseUnit * 24; // 96px

  // Gap widgets using the gap package (more efficient than SizedBox)
  /// Extra small gap: 4px
  static const Widget gapXs = Gap(xs);

  /// Small gap: 8px
  static const Widget gapSm = Gap(sm);

  /// Medium gap: 16px
  static const Widget gapMd = Gap(md);

  /// Large gap: 24px
  static const Widget gapLg = Gap(lg);

  /// Extra large gap: 32px
  static const Widget gapXl = Gap(xl);

  /// Extra extra large gap: 48px
  static const Widget gapXxl = Gap(xxl);

  /// Massive gap: 64px
  static const Widget gapXxxl = Gap(xxxl);

  /// Huge gap: 96px
  static const Widget gapXxxxl = Gap(xxxxl);

  // Horizontal gaps
  /// Extra small horizontal gap: 4px
  static const Widget hGapXs = Gap(xs);

  /// Small horizontal gap: 8px
  static const Widget hGapSm = Gap(sm);

  /// Medium horizontal gap: 16px
  static const Widget hGapMd = Gap(md);

  /// Large horizontal gap: 24px
  static const Widget hGapLg = Gap(lg);

  /// Extra large horizontal gap: 32px
  static const Widget hGapXl = Gap(xl);

  // Common EdgeInsets for padding and margins
  /// Extra small padding on all sides
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);

  /// Small padding on all sides
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);

  /// Medium padding on all sides
  static const EdgeInsets paddingMd = EdgeInsets.all(md);

  /// Large padding on all sides
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);

  /// Extra large padding on all sides
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal padding
  /// Horizontal small padding
  static const EdgeInsets hPaddingSm = EdgeInsets.symmetric(horizontal: sm);

  /// Horizontal medium padding
  static const EdgeInsets hPaddingMd = EdgeInsets.symmetric(horizontal: md);

  /// Horizontal large padding
  static const EdgeInsets hPaddingLg = EdgeInsets.symmetric(horizontal: lg);

  /// Horizontal extra large padding
  static const EdgeInsets hPaddingXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  /// Vertical small padding
  static const EdgeInsets vPaddingSm = EdgeInsets.symmetric(vertical: sm);

  /// Vertical medium padding
  static const EdgeInsets vPaddingMd = EdgeInsets.symmetric(vertical: md);

  /// Vertical large padding
  static const EdgeInsets vPaddingLg = EdgeInsets.symmetric(vertical: lg);

  /// Vertical extra large padding
  static const EdgeInsets vPaddingXl = EdgeInsets.symmetric(vertical: xl);

  // Semantic spacing for specific components
  /// Default page padding (24px horizontal, 16px vertical)
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Card padding (16px on all sides)
  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  /// Card large padding (24px on all sides)
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(lg);

  /// Form field spacing between fields
  static const EdgeInsets formFieldSpacing = EdgeInsets.only(bottom: md);

  /// Button padding (16px horizontal, 8px vertical)
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  /// Large button padding (24px horizontal, 12px vertical)
  static const EdgeInsets buttonPaddingLg = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm + xs,
  );

  /// List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  /// Section spacing (space between major sections)
  static const Widget sectionGap = Gap(xxxl);

  /// Content spacing (space between content blocks)
  static const Widget contentGap = Gap(xl);

  /// Element spacing (space between related elements)
  static const Widget elementGap = Gap(lg);

  /// Field spacing (space between form fields)
  static const Widget fieldGap = Gap(md);

  /// Item spacing (space between list items or small elements)
  static const Widget itemGap = Gap(sm);
}

/// Extension to provide gap widgets for spacing constants
extension SpacingGapExtension on double {
  /// Convert spacing double to Gap widget
  Widget get gap => Gap(this);
}

/// Extension to provide responsive spacing based on screen size
extension ResponsiveSpacing on BuildContext {
  /// Get responsive spacing multiplier based on screen width
  double get _spacingMultiplier {
    final width = MediaQuery.of(this).size.width;
    if (width < 600) {
      return 1.0; // Mobile
    } else if (width < 900) {
      return 1.2; // Tablet
    } else {
      return 1.5; // Desktop
    }
  }

  /// Responsive spacing utilities
  AppResponsiveSpacing get spacing => AppResponsiveSpacing._(this);
}

/// Responsive spacing class that adapts to screen size
class AppResponsiveSpacing {
  final BuildContext _context;

  AppResponsiveSpacing._(this._context);

  /// Get responsive spacing multiplier
  double get _multiplier => _context._spacingMultiplier;

  /// Responsive extra small spacing
  double get xs => AppSpacing.xs * _multiplier;

  /// Responsive small spacing
  double get sm => AppSpacing.sm * _multiplier;

  /// Responsive medium spacing
  double get md => AppSpacing.md * _multiplier;

  /// Responsive large spacing
  double get lg => AppSpacing.lg * _multiplier;

  /// Responsive extra large spacing
  double get xl => AppSpacing.xl * _multiplier;

  /// Responsive extra extra large spacing
  double get xxl => AppSpacing.xxl * _multiplier;

  /// Responsive massive spacing
  double get xxxl => AppSpacing.xxxl * _multiplier;

  /// Responsive page padding
  EdgeInsets get pagePadding =>
      EdgeInsets.symmetric(horizontal: lg, vertical: md);

  /// Responsive card padding
  EdgeInsets get cardPadding => EdgeInsets.all(md);

  /// Responsive card large padding
  EdgeInsets get cardPaddingLg => EdgeInsets.all(lg);

  /// Responsive gap widgets
  Widget get gapXs => Gap(xs);
  Widget get gapSm => Gap(sm);
  Widget get gapMd => Gap(md);
  Widget get gapLg => Gap(lg);
  Widget get gapXl => Gap(xl);
}
