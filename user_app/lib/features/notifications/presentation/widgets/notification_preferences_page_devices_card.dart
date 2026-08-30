part of '../screens/notification_preferences_page.dart';

class _DevicesCard extends ConsumerWidget {
  const _DevicesCard({required this.devices, required this.globalPushEnabled});

  final List<NotificationDevice> devices;
  final bool globalPushEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Section(
      title: 'Registered devices',
      description: devices.isEmpty
          ? 'This device will appear after notification permission and token registration succeed.'
          : 'Control push delivery separately for each signed-in installation.',
      children: devices.isEmpty
          ? const [
              ListTile(
                leading: Icon(LucideIcons.smartphone),
                title: Text('No push installations registered'),
              ),
            ]
          : [
              for (final device in devices)
                SwitchListTile.adaptive(
                  secondary: Icon(
                    device.platform == 'ios'
                        ? LucideIcons.apple
                        : LucideIcons.smartphone,
                  ),
                  title: Text(
                    '${device.platform.toUpperCase()}${device.appVersion == null ? '' : ' · ${device.appVersion}'}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Last active ${MaterialLocalizations.of(context).formatShortDate(device.lastSeenAt.toLocal())}',
                  ),
                  value: globalPushEnabled && device.notificationsEnabled,
                  onChanged: globalPushEnabled
                      ? (enabled) => ref
                            .read(
                              notificationPreferencesControllerProvider
                                  .notifier,
                            )
                            .setDevicePushEnabled(device.id, enabled)
                      : null,
                ),
            ],
    );
  }
}
