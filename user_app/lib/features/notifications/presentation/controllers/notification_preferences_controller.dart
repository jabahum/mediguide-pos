import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/notifications/data/models/notification_preferences.dart';

final notificationPreferencesControllerProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationPreferencesController,
      NotificationPreferencesState
    >(NotificationPreferencesController.new);

final class NotificationPreferencesState {
  const NotificationPreferencesState({
    required this.preferences,
    required this.devices,
  });

  final NotificationPreferences preferences;
  final List<NotificationDevice> devices;
}

final class NotificationPreferencesController
    extends AutoDisposeAsyncNotifier<NotificationPreferencesState> {
  @override
  Future<NotificationPreferencesState> build() => _load();

  Future<NotificationPreferencesState> _load() async {
    final repository = ref.read(notificationRepositoryProvider);
    final results = await Future.wait<dynamic>([
      repository.getPreferences(),
      repository.listDevices(),
    ]);
    final preferences = results[0] as NotificationPreferences;
    await ref
        .read(firebaseServiceProvider)
        .setOutbreakTopicPreference(
          outbreakAlerts: preferences.outbreakAlerts,
          pushEnabled: preferences.pushEnabled,
        );
    return NotificationPreferencesState(
      preferences: preferences,
      devices: results[1] as List<NotificationDevice>,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading<NotificationPreferencesState>().copyWithPrevious(
      state,
    );
    state = await AsyncValue.guard(_load);
  }

  Future<void> updatePreferences(Map<String, dynamic> changes) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = const AsyncLoading<NotificationPreferencesState>().copyWithPrevious(
      state,
    );
    state = await AsyncValue.guard(() async {
      final preferences = await ref
          .read(notificationRepositoryProvider)
          .updatePreferences(changes);
      final devices = await ref
          .read(notificationRepositoryProvider)
          .listDevices();
      await ref
          .read(firebaseServiceProvider)
          .setOutbreakTopicPreference(
            outbreakAlerts: preferences.outbreakAlerts,
            pushEnabled: preferences.pushEnabled,
          );
      return NotificationPreferencesState(
        preferences: preferences,
        devices: devices,
      );
    });
  }

  Future<void> setDevicePushEnabled(String deviceId, bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = const AsyncLoading<NotificationPreferencesState>().copyWithPrevious(
      state,
    );
    state = await AsyncValue.guard(() async {
      final updated = await ref
          .read(notificationRepositoryProvider)
          .setDevicePushEnabled(deviceId, enabled);
      return NotificationPreferencesState(
        preferences: current.preferences,
        devices: [
          for (final device in current.devices)
            if (device.id == updated.id) updated else device,
        ],
      );
    });
  }
}
