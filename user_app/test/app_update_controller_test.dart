import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/app/features/settings/app_update_controller.dart';

void main() {
  test('reports update checks as unsupported away from Android', () async {
    if (Platform.isAndroid) return;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(appUpdateControllerProvider.future);

    final result = await container
        .read(appUpdateControllerProvider.notifier)
        .check();

    expect(result, AppUpdateResult.unsupported);
    expect(
      container.read(appUpdateControllerProvider).value,
      AppUpdateResult.unsupported,
    );
  });
}
