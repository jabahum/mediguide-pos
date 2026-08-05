import 'package:flutter/material.dart';
import 'package:user_app/core/widgets/empty_state.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) =>
      EmptyState.error(description: error.toString(), onAction: onRetry);
}
