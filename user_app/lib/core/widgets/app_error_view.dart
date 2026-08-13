import 'package:flutter/material.dart';

import 'package:user_app/core/widgets/empty_state.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.title,
    this.message,
  });

  final Object error;
  final VoidCallback? onRetry;
  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return EmptyState.error(
      title: title,
      description: message ?? _friendlyMessage(error),
      actionLabel: onRetry == null ? null : 'Try Again',
      onAction: onRetry,
    );
  }

  String _friendlyMessage(Object error) {
    final value = error.toString().trim();

    if (value.isEmpty) {
      return 'An unexpected error occurred.';
    }

    final normalized = value.toLowerCase();
    if (normalized.contains('sqliteexception') ||
        normalized.contains('no such table') ||
        normalized.contains('sql logic error')) {
      return 'Offline content could not be prepared on this device. '
          'Please try again. If the problem continues, restart the app.';
    }

    return value;
  }
}
