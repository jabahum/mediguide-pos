import 'package:flutter/material.dart';

enum AppMessageType { success, error, warning, info }

class AppMessage {
  const AppMessage._();

  static void show(
    BuildContext context, {
    required String message,
    AppMessageType type = AppMessageType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
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

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          content: Row(
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
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: messenger.hideCurrentSnackBar,
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, type: AppMessageType.success);
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message: message,
      type: AppMessageType.error,
      duration: const Duration(seconds: 5),
    );
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, type: AppMessageType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message);
  }
}
