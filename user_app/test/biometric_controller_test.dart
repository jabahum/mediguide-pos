import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/app/data/services/auth_service.dart';
import 'package:user_app/app/features/auth/biometric_controller.dart';
import 'package:user_app/app/core/di/core_providers.dart';

final class FakeBiometricAuthService extends AuthService {
  FakeBiometricAuthService({required this.available, required bool enabled}) {
    isBiometricEnabled.value = enabled;
  }

  final bool available;
  int toggleCalls = 0;

  @override
  Future<bool> checkBiometricAvailability() async => available;

  @override
  Future<bool> toggleBiometricSetting(bool enabled) async {
    toggleCalls++;
    if (!available) return false;
    isBiometricEnabled.value = enabled;
    return true;
  }
}

void main() {
  test('loads and updates biometric preferences through Riverpod', () async {
    final service = FakeBiometricAuthService(available: true, enabled: false);
    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    final initial = await container.read(biometricControllerProvider.future);
    expect(initial.available, isTrue);
    expect(initial.enabled, isFalse);

    final success = await container
        .read(biometricControllerProvider.notifier)
        .setEnabled(true);

    expect(success, isTrue);
    expect(service.toggleCalls, 1);
    expect(container.read(biometricControllerProvider).value?.enabled, isTrue);
  });

  test('does not enable biometrics when unavailable', () async {
    final service = FakeBiometricAuthService(available: false, enabled: false);
    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    await container.read(biometricControllerProvider.future);

    final success = await container
        .read(biometricControllerProvider.notifier)
        .setEnabled(true);

    expect(success, isFalse);
    expect(service.toggleCalls, 0);
  });
}
