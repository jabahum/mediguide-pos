import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';

part 'biometric_controller.g.dart';

final class BiometricState {
  const BiometricState({required this.available, required this.enabled});

  final bool available;
  final bool enabled;

  BiometricState copyWith({bool? available, bool? enabled}) {
    return BiometricState(
      available: available ?? this.available,
      enabled: enabled ?? this.enabled,
    );
  }
}

@riverpod
class BiometricController extends _$BiometricController {
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

    if (current == null || !current.available) {
      return false;
    }

    final success = await ref
        .read(authServiceProvider)
        .toggleBiometricSetting(enabled);

    if (!success) {
      return false;
    }

    state = AsyncData(current.copyWith(enabled: enabled));

    return true;
  }

  Future<void> refreshAvailability() async {
    final service = ref.read(authServiceProvider);

    final current = state.valueOrNull;

    state = const AsyncLoading<BiometricState>();

    state = await AsyncValue.guard(() async {
      final available = await service.checkBiometricAvailability();

      return BiometricState(
        available: available,
        enabled: available ? service.isBiometricEnabled.value : false,
      );
    });

    if (state.hasError && current != null) {
      state = AsyncData(current);
    }
  }
}
