import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/app/data/services/backend_api_service.dart';
import 'package:user_app/app/features/auth/change_password_controller.dart';
import 'package:user_app/app/providers/core_providers.dart';

final class FakePasswordApi extends BackendApiService {
  int requests = 0;
  Completer<Map<String, dynamic>>? pending;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    requests++;
    expect(path, '/api/v2/me/password');
    expect(method, 'POST');
    expect(body, {
      'current_password': 'CurrentPassword9',
      'new_password': 'NewPassword10',
      'new_password_confirm': 'NewPassword10',
    });
    return pending?.future ?? const {'success': true};
  }
}

void main() {
  test('changes password through the typed repository', () async {
    final api = FakePasswordApi();
    final container = ProviderContainer(
      overrides: [backendApiServiceProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    await container.read(changePasswordControllerProvider.future);

    final changed = await container
        .read(changePasswordControllerProvider.notifier)
        .changePassword(
          currentPassword: 'CurrentPassword9',
          newPassword: 'NewPassword10',
          newPasswordConfirm: 'NewPassword10',
        );

    expect(changed, isTrue);
    expect(api.requests, 1);
  });

  test('suppresses duplicate password mutations', () async {
    final api = FakePasswordApi()..pending = Completer<Map<String, dynamic>>();
    final container = ProviderContainer(
      overrides: [backendApiServiceProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    await container.read(changePasswordControllerProvider.future);
    final controller = container.read(
      changePasswordControllerProvider.notifier,
    );

    final first = controller.changePassword(
      currentPassword: 'CurrentPassword9',
      newPassword: 'NewPassword10',
      newPasswordConfirm: 'NewPassword10',
    );
    expect(
      await controller.changePassword(
        currentPassword: 'CurrentPassword9',
        newPassword: 'NewPassword10',
        newPasswordConfirm: 'NewPassword10',
      ),
      isFalse,
    );
    expect(api.requests, 1);
    api.pending!.complete(const {'success': true});
    expect(await first, isTrue);
  });
}
