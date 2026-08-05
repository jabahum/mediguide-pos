import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Responsive utility class providing helper methods for responsive design
class Responsive {
  /// Private constructor to prevent instantiation
  Responsive._();

  /// Check if the current screen is mobile size
  static bool isMobile(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isMobile;
  }

  /// Check if the current screen is tablet size
  static bool isTablet(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isTablet;
  }

  /// Check if the current screen is desktop size
  static bool isDesktop(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isDesktop;
  }

  /// Check if the current screen is 4K size
  static bool is4K(BuildContext context) {
    return ResponsiveBreakpoints.of(context).equals('4K');
  }

  /// Check if screen is larger than mobile
  static bool isLargerThanMobile(BuildContext context) {
    return ResponsiveBreakpoints.of(context).largerThan(MOBILE);
  }

  /// Check if screen is larger than tablet
  static bool isLargerThanTablet(BuildContext context) {
    return ResponsiveBreakpoints.of(context).largerThan(TABLET);
  }

  /// Check if screen is smaller than tablet
  static bool isSmallerThanTablet(BuildContext context) {
    return ResponsiveBreakpoints.of(context).smallerThan(TABLET);
  }

  /// Check if screen is between mobile and tablet
  static bool isBetweenMobileAndTablet(BuildContext context) {
    return ResponsiveBreakpoints.of(context).between(MOBILE, TABLET);
  }

  /// Check if screen is between tablet and desktop
  static bool isBetweenTabletAndDesktop(BuildContext context) {
    return ResponsiveBreakpoints.of(context).between(TABLET, DESKTOP);
  }

  /// Get responsive value based on screen size
  /// Usage: Responsive.value(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? fourK,
  }) {
    if (is4K(context) && fourK != null) return fourK;
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Get responsive double value with sensible defaults
  static double doubleValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? fourK,
  }) {
    return value<double>(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.25,
      desktop: desktop ?? mobile * 1.5,
      fourK: fourK ?? mobile * 2,
    );
  }

  /// Get responsive integer value with sensible defaults
  static int intValue(
    BuildContext context, {
    required int mobile,
    int? tablet,
    int? desktop,
    int? fourK,
  }) {
    return value<int>(
      context,
      mobile: mobile,
      tablet: tablet ?? (mobile * 1.25).round(),
      desktop: desktop ?? (mobile * 1.5).round(),
      fourK: fourK ?? mobile * 2,
    );
  }

  /// Get responsive EdgeInsets
  static EdgeInsets padding(
    BuildContext context, {
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
    EdgeInsets? fourK,
  }) {
    return value<EdgeInsets>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      fourK: fourK,
    );
  }

  /// Get responsive horizontal padding
  static double horizontalPadding(BuildContext context) {
    return doubleValue(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
      fourK: 48.0,
    );
  }

  /// Get responsive vertical padding
  static double verticalPadding(BuildContext context) {
    return doubleValue(
      context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
      fourK: 32.0,
    );
  }

  /// Get responsive font size
  static double fontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? fourK,
  }) {
    return doubleValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      fourK: fourK,
    );
  }

  /// Get responsive icon size
  static double iconSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? fourK,
  }) {
    return doubleValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      fourK: fourK,
    );
  }

  /// Get responsive column count for grids
  static int columnCount(BuildContext context) {
    return intValue(context, mobile: 1, tablet: 2, desktop: 3, fourK: 4);
  }

  /// Get responsive cross axis count for GridView
  static int crossAxisCount(
    BuildContext context, {
    int? mobile,
    int? tablet,
    int? desktop,
    int? fourK,
  }) {
    return intValue(
      context,
      mobile: mobile ?? 2,
      tablet: tablet ?? 3,
      desktop: desktop ?? 4,
      fourK: fourK ?? 6,
    );
  }

  /// Get responsive aspect ratio
  static double aspectRatio(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
    double? fourK,
  }) {
    return doubleValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      fourK: fourK,
    );
  }

  /// Get responsive max width for content
  static double maxContentWidth(BuildContext context) {
    return doubleValue(
      context,
      mobile: double.infinity,
      tablet: 600.0,
      desktop: 800.0,
      fourK: 1000.0,
    );
  }

  /// Check if should show navigation rail instead of bottom navigation
  static bool shouldShowNavigationRail(BuildContext context) {
    return isLargerThanMobile(context);
  }

  /// Check if should show drawer button
  static bool shouldShowDrawerButton(BuildContext context) {
    return isMobile(context);
  }

  /// Get responsive container margin
  static EdgeInsets containerMargin(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding(context),
      vertical: verticalPadding(context),
    );
  }

  /// Get responsive card padding
  static EdgeInsets cardPadding(BuildContext context) {
    return EdgeInsets.all(
      doubleValue(context, mobile: 16.0, tablet: 20.0, desktop: 24.0),
    );
  }

  /// Get responsive dialog width
  static double dialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (isMobile(context)) {
      return screenWidth * 0.9;
    } else if (isTablet(context)) {
      return 500.0;
    } else {
      return 600.0;
    }
  }

  /// Get responsive list item height
  static double listItemHeight(BuildContext context) {
    return doubleValue(context, mobile: 56.0, tablet: 64.0, desktop: 72.0);
  }
}

/// Extension on BuildContext for convenient responsive access
extension ResponsiveExtension on BuildContext {
  /// Quick access to responsive utilities
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  bool get is4K => Responsive.is4K(this);
  bool get isLargerThanMobile => Responsive.isLargerThanMobile(this);
  bool get isLargerThanTablet => Responsive.isLargerThanTablet(this);
  bool get isSmallerThanTablet => Responsive.isSmallerThanTablet(this);

  /// Get responsive values
  T responsiveValue<T>({required T mobile, T? tablet, T? desktop, T? fourK}) =>
      Responsive.value<T>(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
        fourK: fourK,
      );

  /// Get responsive padding
  double get responsiveHorizontalPadding => Responsive.horizontalPadding(this);
  double get responsiveVerticalPadding => Responsive.verticalPadding(this);
  EdgeInsets get responsiveContainerMargin => Responsive.containerMargin(this);
  EdgeInsets get responsiveCardPadding => Responsive.cardPadding(this);
}
