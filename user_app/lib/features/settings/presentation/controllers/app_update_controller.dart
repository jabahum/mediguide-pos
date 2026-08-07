import 'dart:io';

import 'package:in_app_update/in_app_update.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_update_controller.g.dart';

enum AppUpdateResult { unsupported, upToDate, downloading }

@riverpod
class AppUpdateController extends _$AppUpdateController {
  @override
  Future<AppUpdateResult?> build() async {
    return null;
  }

  Future<AppUpdateResult?> check() async {
    if (state.isLoading) {
      return null;
    }

    state = const AsyncLoading();

    try {
      if (!Platform.isAndroid) {
        const result = AppUpdateResult.unsupported;

        state = const AsyncData(result);

        return result;
      }

      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        const result = AppUpdateResult.upToDate;

        state = const AsyncData(result);

        return result;
      }

      try {
        await InAppUpdate.startFlexibleUpdate();
      } catch (_) {
        await InAppUpdate.performImmediateUpdate();
      }

      const result = AppUpdateResult.downloading;

      state = const AsyncData(result);

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
