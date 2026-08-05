import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:user_app/features/profile/presentation/controllers/edit_profile_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';

final class EditProfileSessionStore implements AuthSessionStore {
  EditProfileSessionStore(this.currentUser);
  @override
  User? currentUser;

  @override
  Future<bool> clearUser() async {
    currentUser = null;
    return true;
  }

  @override
  Future<bool> saveUser(User user) async {
    currentUser = user;
    return true;
  }
}

final class EditProfileApi extends BackendApiService {
  EditProfileApi({this.pendingUpdate});
  final Completer<Map<String, dynamic>>? pendingUpdate;
  int updateRequests = 0;
  Map<String, dynamic>? updateBody;

  @override
  bool get isAuthenticated => true;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    if (path == '/api/v2/me') {
      return {
        'data': {'id': 'user-1', 'name': 'Original User', 'email': 'u@test'},
      };
    }
    expect(path, '/api/v2/users/user-1');
    expect(method, 'PATCH');
    updateRequests++;
    updateBody = body;
    return pendingUpdate?.future ??
        {
          'data': {'id': 'user-1', 'name': 'Updated User', 'email': 'u@test'},
        };
  }
}

Future<ProviderContainer> createEditContainer(EditProfileApi api) async {
  final store = EditProfileSessionStore(
    User({'id': 'user-1', 'name': 'Original User', 'email': 'u@test'}),
  );
  final container = ProviderContainer(
    overrides: [
      backendApiServiceProvider.overrideWithValue(api),
      authSessionStoreProvider.overrideWithValue(store),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authControllerProvider.future);
  return container;
}

void main() {
  test('updates allowed fields and replaces authenticated user', () async {
    final api = EditProfileApi();
    final container = await createEditContainer(api);
    final controller = container.read(editProfileControllerProvider.notifier);
    controller.setHasChanges(true);

    final saved = await controller.save({
      'name': 'Updated User',
      'city': 'Kampala',
      'role': 'admin',
    });

    expect(saved, isTrue);
    expect(api.updateBody, {'name': 'Updated User', 'city': 'Kampala'});
    expect(
      container.read(authControllerProvider).value?.user?.name,
      'Updated User',
    );
    expect(container.read(editProfileControllerProvider).hasChanges, isFalse);
  });

  test('suppresses duplicate profile mutations', () async {
    final pending = Completer<Map<String, dynamic>>();
    final api = EditProfileApi(pendingUpdate: pending);
    final container = await createEditContainer(api);
    final controller = container.read(editProfileControllerProvider.notifier);
    controller.setHasChanges(true);

    final first = controller.save({'name': 'Updated User'});
    expect(await controller.save({'name': 'Updated Again'}), isFalse);
    expect(api.updateRequests, 1);
    pending.complete({
      'data': {'id': 'user-1', 'name': 'Updated User', 'email': 'u@test'},
    });
    expect(await first, isTrue);
  });
}
