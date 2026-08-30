part of '../screens/notification_preferences_page.dart';

class _SystemPermissionCard extends ConsumerWidget {
  const _SystemPermissionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(firebaseServiceProvider);
    final state =
        ref.watch(notificationPermissionProvider).valueOrNull ??
        service.permissionState;
    final (title, description, canRequest, needsSettings) = switch (state) {
      AppNotificationPermissionState.notDetermined => (
        'System permission not requested',
        'Allow notifications to receive approved clinical and outbreak alerts.',
        true,
        false,
      ),
      AppNotificationPermissionState.provisional => (
        'Notifications delivered quietly',
        'iOS is delivering provisional notifications. You can allow prominent alerts in Settings.',
        false,
        true,
      ),
      AppNotificationPermissionState.authorized => (
        'System notifications allowed',
        'This device can receive push notifications when your preferences allow them.',
        false,
        false,
      ),
      AppNotificationPermissionState.denied => (
        'Notifications denied',
        'You can request permission again or manage this app in system Settings.',
        true,
        true,
      ),
      AppNotificationPermissionState.permanentlyDenied => (
        'Notifications blocked',
        'Permission must be restored from this app’s system Settings.',
        false,
        true,
      ),
    };
    return Card(
      child: Padding(
        padding: AppSpacing.paddingSm,
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                state == AppNotificationPermissionState.authorized
                    ? LucideIcons.circleCheck
                    : LucideIcons.bellOff,
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(description),
            ),
            if (canRequest || needsSettings)
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    if (canRequest)
                      TextButton(
                        onPressed: service.enabled
                            ? service.requestNotificationPermission
                            : null,
                        child: const Text('Allow'),
                      ),
                    if (needsSettings)
                      TextButton(
                        onPressed: service.enabled
                            ? service.openNotificationSettings
                            : null,
                        child: const Text('Settings'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
