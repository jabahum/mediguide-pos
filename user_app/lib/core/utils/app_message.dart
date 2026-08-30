import 'package:flutter/material.dart';

enum AppMessageType { success, error, warning, info }

class AppMessage {
  const AppMessage._();

  static const Duration defaultDuration = Duration(seconds: 3);
  static const Duration errorDuration = Duration(seconds: 5);

  static void show(
    BuildContext context, {
    required String message,
    AppMessageType type = AppMessageType.info,
    Duration duration = defaultDuration,
    String? actionLabel,
    VoidCallback? onAction,
    bool replaceCurrent = true,
  }) {
    assert(
      actionLabel == null || onAction != null,
      'onAction is required when actionLabel is provided.',
    );

    final theme = Theme.of(context);

    final backgroundColor = switch (type) {
      AppMessageType.success => Colors.green.shade700,
      AppMessageType.error => theme.colorScheme.error,
      AppMessageType.warning => Colors.orange.shade800,
      AppMessageType.info => theme.colorScheme.inverseSurface,
    };

    final icon = switch (type) {
      AppMessageType.success => Icons.check_circle_outline,
      AppMessageType.error => Icons.error_outline,
      AppMessageType.warning => Icons.warning_amber_outlined,
      AppMessageType.info => Icons.info_outline,
    };

    final messenger = ScaffoldMessenger.of(context);
    final resolvedActionLabel = actionLabel?.trim();
    final hasCustomAction = resolvedActionLabel?.isNotEmpty == true;

    if (replaceCurrent) {
      messenger.hideCurrentSnackBar();
    }

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        content: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        action: SnackBarAction(
          label: hasCustomAction ? resolvedActionLabel! : 'DISMISS',
          textColor: Colors.white,
          onPressed: hasCustomAction
              ? onAction!
              : messenger.hideCurrentSnackBar,
        ),
      ),
    );
  }

  static void success(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppMessageType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = errorDuration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppMessageType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppMessageType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
