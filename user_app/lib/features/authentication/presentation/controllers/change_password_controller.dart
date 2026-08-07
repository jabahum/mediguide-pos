import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';

part 'change_password_controller.g.dart';

@riverpod
class ChangePasswordController extends _$ChangePasswordController {
  @override
  Future<void> build() async {}

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    if (state.isLoading) {
      return false;
    }

    state = const AsyncLoading();

    try {
      await ref
          .read(userRepositoryProvider)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
            newPasswordConfirm: newPasswordConfirm,
          );

      state = const AsyncData(null);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
