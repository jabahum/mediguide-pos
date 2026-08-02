import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';

final changePasswordControllerProvider =
    AutoDisposeAsyncNotifierProvider<ChangePasswordController, void>(
      ChangePasswordController.new,
    );

class ChangePasswordController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    if (state.isLoading) return false;
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
