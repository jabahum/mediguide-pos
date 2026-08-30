part of '../screens/notification_preferences_page.dart';

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
