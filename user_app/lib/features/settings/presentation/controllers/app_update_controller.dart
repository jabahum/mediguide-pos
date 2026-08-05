import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

enum AppUpdateResult { unsupported, upToDate, downloading }

final appUpdateControllerProvider =
    AutoDisposeAsyncNotifierProvider<AppUpdateController, AppUpdateResult?>(
      AppUpdateController.new,
    );

class AppUpdateController extends AutoDisposeAsyncNotifier<AppUpdateResult?> {
  @override
  Future<AppUpdateResult?> build() async => null;

  Future<AppUpdateResult?> check() async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    try {
      if (!Platform.isAndroid) {
        state = const AsyncData(AppUpdateResult.unsupported);
        return AppUpdateResult.unsupported;
      }

      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        state = const AsyncData(AppUpdateResult.upToDate);
        return AppUpdateResult.upToDate;
      }

      try {
        await InAppUpdate.startFlexibleUpdate();
      } catch (_) {
        await InAppUpdate.performImmediateUpdate();
      }
      state = const AsyncData(AppUpdateResult.downloading);
      return AppUpdateResult.downloading;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
