import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation boundary used by non-widget collaborators and shared helpers.
/// Feature widgets should prefer `context.push`, `context.go`, and
/// `Navigator.pop` when they already own a BuildContext.
abstract final class AppNavigator {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext get context {
    final value = navigatorKey.currentContext;
    if (value == null) throw StateError('Navigator is not mounted');
    return value;
  }

  static ThemeData get theme => Theme.of(context);
  static TextTheme get textTheme => theme.textTheme;

  static Future<T?> pushNamed<T>(String location, {Object? arguments}) =>
      context.push<T>(location, extra: arguments);

  static void go(String location, {Object? arguments}) =>
      context.go(location, extra: arguments);

  static void pop<T>({T? result}) {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop(result);
  }

  static Future<T?> dialog<T>(Widget child, {bool barrierDismissible = true}) =>
      showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (_) => child,
      );

  static Future<T?> bottomSheet<T>(
    Widget child, {
    Color? backgroundColor,
    ShapeBorder? shape,
    Clip? clipBehavior,
    bool isScrollControlled = false,
    bool enableDrag = true,
    bool isDismissible = true,
  }) => showModalBottomSheet<T>(
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
