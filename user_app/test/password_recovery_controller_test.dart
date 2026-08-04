import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/app/data/services/backend_api_service.dart';
import 'package:user_app/app/features/auth/password_recovery_controller.dart';
import 'package:user_app/app/core/di/core_providers.dart';

final class FakeRecoveryApi extends BackendApiService {
  int requestCount = 0;
  Map<String, dynamic> response = {
    'data': {
      'accepted': true,
      'delivery_accepted': false,
      'development_token': 'development-only',
    },
  };
  Completer<Map<String, dynamic>>? pendingRequest;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    expect(path, '/api/v2/auth/password-reset/request');
    expect(method, 'POST');
    expect(body, {'email': 'clinician@example.com'});
    expect(includeAuth, isFalse);
    requestCount++;
    return pendingRequest?.future ?? response;
  }
}

void main() {
  test('reports the backend delivery result honestly', () async {
    final api = FakeRecoveryApi();
    final container = ProviderContainer(
      overrides: [backendApiServiceProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    await container.read(passwordRecoveryControllerProvider.future);

    final result = await container
        .read(passwordRecoveryControllerProvider.notifier)
        .requestReset(' clinician@example.com ');

    expect(result?.accepted, isTrue);
    expect(result?.deliveryAccepted, isFalse);
    expect(result?.hasDevelopmentToken, isTrue);
  });

  test('suppresses a duplicate reset request while one is pending', () async {
    final api = FakeRecoveryApi()
      ..pendingRequest = Completer<Map<String, dynamic>>();
    final container = ProviderContainer(
      overrides: [backendApiServiceProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    await container.read(passwordRecoveryControllerProvider.future);
    final controller = container.read(
      passwordRecoveryControllerProvider.notifier,
    );

    final first = controller.requestReset('clinician@example.com');
    expect(await controller.requestReset('clinician@example.com'), isNull);
    expect(api.requestCount, 1);

    api.pendingRequest!.complete(api.response);
    expect((await first)?.accepted, isTrue);
  });
}
