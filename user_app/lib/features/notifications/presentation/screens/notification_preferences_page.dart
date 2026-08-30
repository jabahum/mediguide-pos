import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/features/notifications/data/models/notification_preferences.dart';
import 'package:user_app/features/notifications/presentation/controllers/notification_preferences_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/services/firebase_service.dart';

part '../widgets/notification_preferences_page_widgets.dart';

class NotificationPreferencesPage extends ConsumerWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(notificationPreferencesControllerProvider);
    ref.listen(notificationPreferencesControllerProvider, (previous, next) {
      if (next.hasError && previous?.error != next.error) {
        AppMessage.error(context, 'Unable to update notification settings.');
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Notification settings')),
      body: asyncState.when(
        skipLoadingOnRefresh: true,
        data: (state) => RefreshIndicator(
          onRefresh: () => ref
              .read(notificationPreferencesControllerProvider.notifier)
              .refresh(),
          child: _PreferencesContent(state: state),
        ),
        loading: () =>
            const AppLoadingView(message: 'Loading notification settings...'),
        error: (error, _) => AppErrorView(
          error: error,
          title: 'Notification settings unavailable',
          message: 'Check your connection and try again.',
          onRetry: () =>
              ref.invalidate(notificationPreferencesControllerProvider),
        ),
      ),
    );
  }
}
