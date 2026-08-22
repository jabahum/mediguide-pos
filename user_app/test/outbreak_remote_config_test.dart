import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/services/firebase_service.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/features/outbreaks/presentation/providers/outbreak_providers.dart';

void main() {
  test('public outbreak topic requires config, preference and permission', () {
    expect(
      shouldSubscribeToPublicOutbreaks(
        remoteEnabled: true,
        pushEnabled: true,
        userOptedIn: true,
        permissionState: AppNotificationPermissionState.authorized,
      ),
      isTrue,
    );
    for (final permission in [
      AppNotificationPermissionState.denied,
      AppNotificationPermissionState.permanentlyDenied,
      AppNotificationPermissionState.notDetermined,
    ]) {
      expect(
        shouldSubscribeToPublicOutbreaks(
          remoteEnabled: true,
          pushEnabled: true,
          userOptedIn: true,
          permissionState: permission,
        ),
        isFalse,
      );
    }
    expect(
      shouldSubscribeToPublicOutbreaks(
        remoteEnabled: false,
        pushEnabled: true,
        userOptedIn: true,
        permissionState: AppNotificationPermissionState.authorized,
      ),
      isFalse,
    );
  });

  test('monitoring content never becomes the primary emergency banner', () {
    const monitoring = PublicOutbreak(
      id: 'monitoring',
      status: 'monitoring',
      title: 'Monitoring update',
    );
    const active = PublicOutbreak(
      id: 'active',
      status: 'active',
      title: 'Active response',
    );
    expect(selectPrimaryOutbreak(const [monitoring]), isNull);
    expect(selectPrimaryOutbreak(const [monitoring, active])?.id, 'active');
    expect(selectPrimaryOutbreak(const []), isNull);
  });

  test(
    'disabled Remote Config returns an empty feed without fetching',
    () async {
      final container = ProviderContainer(
        overrides: [outbreakFeatureEnabledProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);
      final page = await container.read(publicOutbreaksProvider.future);
      expect(page.items, isEmpty);
      expect(page.totalItems, 0);
    },
  );
}
