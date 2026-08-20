import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/features/notifications/data/models/notification_preferences.dart';
import 'package:user_app/features/notifications/presentation/controllers/notification_preferences_controller.dart';

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

class _PreferencesContent extends ConsumerWidget {
  const _PreferencesContent({required this.state});

  final NotificationPreferencesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = state.preferences;
    final controller = ref.read(
      notificationPreferencesControllerProvider.notifier,
    );
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      children: [
        const _IntroCard(),
        AppSpacing.gapLg,
        _Section(
          title: 'Delivery channels',
          description:
              'Turning push off disables every registered device. Turning it on again does not silently re-enable individual devices.',
          children: [
            _PreferenceSwitch(
              icon: LucideIcons.smartphone,
              title: 'Push notifications',
              subtitle: 'Receive alerts on enabled installations',
              value: preferences.pushEnabled,
              onChanged: (value) =>
                  controller.updatePreferences({'push_enabled': value}),
            ),
            _PreferenceSwitch(
              icon: LucideIcons.inbox,
              title: 'In-app notifications',
              subtitle: 'Show notifications in your MediGuide inbox',
              value: preferences.inAppEnabled,
              onChanged: (value) =>
                  controller.updatePreferences({'in_app_enabled': value}),
            ),
          ],
        ),
        AppSpacing.gapLg,
        _Section(
          title: 'Notification categories',
          description:
              'Emergency alerts remain your choice. Urgent emergency alerts may bypass quiet hours, but never a channel or category opt-out.',
          children: [
            _category(
              controller,
              'Clinical content updates',
              'New and revised clinical guidance',
              'clinical_content_updates',
              preferences.clinicalContentUpdates,
            ),
            _category(
              controller,
              'Outbreak alerts',
              'Outbreak declarations and situation updates',
              'outbreak_alerts',
              preferences.outbreakAlerts,
            ),
            _category(
              controller,
              'Emergency alerts',
              'Urgent public-health and clinical alerts',
              'emergency_alerts',
              preferences.emergencyAlerts,
              icon: LucideIcons.triangleAlert,
            ),
            _category(
              controller,
              'Reminders',
              'Saved content and clinical reminders',
              'reminders',
              preferences.reminders,
            ),
            _category(
              controller,
              'System notices',
              'Important service and account notices',
              'system_notices',
              preferences.systemNotices,
            ),
            _category(
              controller,
              'Product announcements',
              'New MediGuide features and improvements',
              'product_announcements',
              preferences.productAnnouncements,
            ),
          ],
        ),
        AppSpacing.gapLg,
        _QuietHoursCard(preferences: preferences),
        AppSpacing.gapLg,
        _LanguageCard(preferences: preferences),
        AppSpacing.gapLg,
        _DevicesCard(
          devices: state.devices,
          globalPushEnabled: preferences.pushEnabled,
        ),
      ],
    );
  }

  Widget _category(
    NotificationPreferencesController controller,
    String title,
    String subtitle,
    String key,
    bool value, {
    IconData icon = LucideIcons.bell,
  }) {
    return _PreferenceSwitch(
      icon: icon,
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: (enabled) => controller.updatePreferences({key: enabled}),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colors.primaryContainer,
            child: Icon(LucideIcons.bellRing, color: colors.primary),
          ),
          AppSpacing.hGapMd,
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose what reaches you',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Settings are stored securely against your signed-in account.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
        AppSpacing.gapSm,
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _QuietHoursCard extends ConsumerWidget {
  const _QuietHoursCard({required this.preferences});

  final NotificationPreferences preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      notificationPreferencesControllerProvider.notifier,
    );
    final start = preferences.quietHoursStart ?? '22:00';
    final end = preferences.quietHoursEnd ?? '06:00';
    return _Section(
      title: 'Quiet hours',
      description:
          'Delay non-emergency push alerts until your quiet period ends.',
      children: [
        _PreferenceSwitch(
          icon: LucideIcons.moon,
          title: 'Use quiet hours',
          subtitle: '$start–$end · ${preferences.quietHoursTimezone}',
          value: preferences.quietHoursEnabled,
          onChanged: (enabled) => controller.updatePreferences({
            'quiet_hours_enabled': enabled,
            'quiet_hours_start': start,
            'quiet_hours_end': end,
            'quiet_hours_timezone': preferences.quietHoursTimezone,
          }),
        ),
        ListTile(
          enabled: preferences.quietHoursEnabled,
          leading: const Icon(LucideIcons.clock3),
          title: const Text('Quiet period'),
          subtitle: Text('$start–$end'),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: preferences.quietHoursEnabled
              ? () => _pickQuietHours(context, ref, start, end)
              : null,
        ),
        ListTile(
          enabled: preferences.quietHoursEnabled,
          leading: const Icon(LucideIcons.globe2),
          title: const Text('Time zone'),
          trailing: DropdownButton<String>(
            value: _quietHourTimezones.contains(preferences.quietHoursTimezone)
                ? preferences.quietHoursTimezone
                : 'UTC',
            underline: const SizedBox.shrink(),
            items: [
              for (final timezone in _quietHourTimezones)
                DropdownMenuItem(value: timezone, child: Text(timezone)),
            ],
            onChanged: preferences.quietHoursEnabled
                ? (value) {
                    if (value != null) {
                      controller.updatePreferences({
                        'quiet_hours_timezone': value,
                      });
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _pickQuietHours(
    BuildContext context,
    WidgetRef ref,
    String start,
    String end,
  ) async {
    TimeOfDay parse(String value) {
      final parts = value.split(':');
      return TimeOfDay(
        hour: int.tryParse(parts.first) ?? 22,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
      );
    }

    String format(TimeOfDay value) =>
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    final selectedStart = await showTimePicker(
      context: context,
      initialTime: parse(start),
      helpText: 'Quiet hours start',
    );
    if (selectedStart == null || !context.mounted) return;
    final selectedEnd = await showTimePicker(
      context: context,
      initialTime: parse(end),
      helpText: 'Quiet hours end',
    );
    if (selectedEnd == null) return;
    await ref
        .read(notificationPreferencesControllerProvider.notifier)
        .updatePreferences({
          'quiet_hours_enabled': true,
          'quiet_hours_start': format(selectedStart),
          'quiet_hours_end': format(selectedEnd),
          'quiet_hours_timezone': preferences.quietHoursTimezone,
        });
  }
}

const _quietHourTimezones = <String>[
  'Africa/Kampala',
  'Africa/Nairobi',
  'Africa/Kigali',
  'Africa/Dar_es_Salaam',
  'Africa/Juba',
  'Africa/Lusaka',
  'Africa/Johannesburg',
  'UTC',
];

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard({required this.preferences});

  final NotificationPreferences preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Section(
      title: 'Notification language',
      description: 'Select the preferred language for localized messages.',
      children: [
        ListTile(
          leading: const Icon(LucideIcons.languages),
          title: const Text('Preferred language'),
          trailing: DropdownButton<String>(
            value: {'en', 'sw'}.contains(preferences.preferredLanguage)
                ? preferences.preferredLanguage
                : 'en',
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'sw', child: Text('Kiswahili')),
            ],
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(notificationPreferencesControllerProvider.notifier)
                    .updatePreferences({'preferred_language': value});
              }
            },
          ),
        ),
      ],
    );
  }
}

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
