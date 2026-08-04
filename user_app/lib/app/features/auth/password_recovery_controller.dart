import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/core_providers.dart';

final passwordRecoveryControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      PasswordRecoveryController,
      PasswordRecoveryResult?
    >(PasswordRecoveryController.new);

final class PasswordRecoveryResult {
  const PasswordRecoveryResult({
    required this.accepted,
    required this.deliveryAccepted,
    required this.hasDevelopmentToken,
  });

  factory PasswordRecoveryResult.fromJson(Map<String, dynamic> value) =>
      PasswordRecoveryResult(
        accepted: value['accepted'] == true,
        deliveryAccepted: value['delivery_accepted'] == true,
        hasDevelopmentToken:
            value['development_token']?.toString().isNotEmpty == true,
      );

  final bool accepted;
  final bool deliveryAccepted;
  final bool hasDevelopmentToken;
}

class PasswordRecoveryController
    extends AutoDisposeAsyncNotifier<PasswordRecoveryResult?> {
  @override
  Future<PasswordRecoveryResult?> build() async => null;

  Future<PasswordRecoveryResult?> requestReset(String email) async {
    if (state.isLoading) return null;

    state = const AsyncLoading();
    try {
      final response = await ref
          .read(userRepositoryProvider)
          .requestPasswordReset(email.trim());
      final result = PasswordRecoveryResult.fromJson(response);
      state = AsyncData(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
