import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation boundary used by non-widget collaborators and shared helpers.
///
/// Feature widgets should prefer:
/// - context.push(...)
/// - context.go(...)
/// - context.pop(...)
///
/// Use AppNavigator only where BuildContext is unavailable.
abstract final class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext get context {
    final currentContext = navigatorKey.currentContext;

    if (currentContext == null) {
      throw StateError(
        'AppNavigator is not mounted. Ensure AppNavigator.navigatorKey '
        'is assigned to GoRouter.navigatorKey.',
      );
    }

    return currentContext;
  }

  static ThemeData get theme => Theme.of(context);

  static TextTheme get textTheme => theme.textTheme;

  /// Pushes a route using its URL location/path.
  ///
  /// Example:
  /// AppNavigator.push('/guidelines/123');
  static Future<T?> push<T extends Object?>(String location, {Object? extra}) {
    return context.push<T>(location, extra: extra);
  }

  /// Pushes a route using its configured GoRoute name.
  ///
  /// Example:
  /// AppNavigator.pushNamed(
  ///   'guideline-details',
  ///   pathParameters: {'guidelineId': '123'},
  /// );
  static Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) {
    return context.pushNamed<T>(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// Navigates to a URL location and replaces the current route stack.
  static void go(String location, {Object? extra}) {
    context.go(location, extra: extra);
  }

  /// Navigates using a configured GoRoute name.
  static void goNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) {
    context.goNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  static bool canPop() => context.canPop();

  static void pop<T extends Object?>([T? result]) {
    if (context.canPop()) {
      context.pop<T>(result);
    }
  }

  static Future<T?> dialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => child,
    );
  }

  static Future<T?> bottomSheet<T>({
    required Widget child,
    Color? backgroundColor,
    ShapeBorder? shape,
    Clip? clipBehavior,
    bool isScrollControlled = false,
    bool enableDrag = true,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: backgroundColor,
      shape: shape,
      clipBehavior: clipBehavior,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      builder: (_) => child,
    );
  }
}
