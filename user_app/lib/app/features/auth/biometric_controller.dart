import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/core_providers.dart';

final class BiometricState {
  const BiometricState({required this.available, required this.enabled});
  final bool available;
  final bool enabled;
}

final biometricControllerProvider =
    AsyncNotifierProvider<BiometricController, BiometricState>(
      BiometricController.new,
    );

class BiometricController extends AsyncNotifier<BiometricState> {
  @override
  Future<BiometricState> build() async {
    final service = ref.watch(authServiceProvider);
    final available = await service.checkBiometricAvailability();
    return BiometricState(
      available: available,
      enabled: service.isBiometricEnabled.value,
    );
  }

  Future<bool> setEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null || !current.available) return false;
    final success = await ref
        .read(authServiceProvider)
        .toggleBiometricSetting(enabled);
    if (success) {
      state = AsyncData(
        BiometricState(available: current.available, enabled: enabled),
      );
    }
    return success;
  }
}
