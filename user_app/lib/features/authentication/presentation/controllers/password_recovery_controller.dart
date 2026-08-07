import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';

part 'password_recovery_controller.g.dart';

final class PasswordRecoveryResult {
  const PasswordRecoveryResult({
    required this.accepted,
    required this.deliveryAccepted,
    required this.hasDevelopmentToken,
  });

  factory PasswordRecoveryResult.fromJson(Map<String, dynamic> value) {
    return PasswordRecoveryResult(
      accepted: value['accepted'] == true,
      deliveryAccepted: value['delivery_accepted'] == true,
      hasDevelopmentToken:
          value['development_token']?.toString().isNotEmpty == true,
    );
  }

  final bool accepted;
  final bool deliveryAccepted;
  final bool hasDevelopmentToken;
}

@riverpod
class PasswordRecoveryController extends _$PasswordRecoveryController {
  @override
  Future<PasswordRecoveryResult?> build() async {
    return null;
  }

  Future<PasswordRecoveryResult?> requestReset(String email) async {
    if (state.isLoading) {
      return null;
    }

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

  void reset() {
    state = const AsyncData(null);
  }
}
