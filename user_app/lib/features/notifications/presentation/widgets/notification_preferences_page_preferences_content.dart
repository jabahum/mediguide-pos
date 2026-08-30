part of '../screens/notification_preferences_page.dart';

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
        const _SystemPermissionCard(),
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
