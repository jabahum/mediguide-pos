import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/app/data/models/models.dart';
import 'package:user_app/app/data/repositories/calculator_repository.dart';
import 'package:user_app/app/data/services/backend_api_service.dart';
import 'package:user_app/app/features/auth/auth_controller.dart';
import 'package:user_app/app/features/auth/auth_session_store.dart';
import 'package:user_app/app/features/tools/use_calculator_controller.dart';
import 'package:user_app/app/features/tools/tools_controller.dart';
import 'package:user_app/app/core/di/core_providers.dart';

final class EmptyToolSessionStore implements AuthSessionStore {
  @override
  User? currentUser;
  @override
  Future<bool> clearUser() async => true;
  @override
  Future<bool> saveUser(User user) async => true;
}

final class ToolApi extends BackendApiService {
  @override
  bool get isAuthenticated => false;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    if (path == '/api/v2/calculators/calculator-1') {
      return {
        'data': {
          'id': 'calculator-1',
          'name': 'BMI',
          'type': 'calculator',
          'status': 'active',
          'app_file_json': {'path': 'bmi.html'},
        },
      };
    }
    throw StateError('Unexpected request: $method $path');
  }
}

final class MemoryCalculatorLoader implements CalculatorContentLoader {
  Calculator? loaded;

  @override
  Future<CalculatorContent> load(Calculator calculator) async {
    loaded = calculator;
    return const CalculatorContent(
      html: '<html><body>BMI</body></html>',
      baseUrl: 'https://api.example.test/calculators/',
    );
  }
}

void main() {
  test('tool catalogue applies its initial tab through scoped state', () {
    final controller = ToolsController(CalculatorRepository(ToolApi()), const {
      'initialTab': 2,
    });
    addTearDown(controller.dispose);

    expect(controller.selectedTabIndex, 2);
    expect(controller.hasActiveFilters, isTrue);
  });

  test('calculator runner resolves an id and exposes loaded HTML', () async {
    final api = ToolApi();
    final loader = MemoryCalculatorLoader();
    final container = ProviderContainer(
      overrides: [
        backendApiServiceProvider.overrideWithValue(api),
        authSessionStoreProvider.overrideWithValue(EmptyToolSessionStore()),
        calculatorContentLoaderProvider.overrideWithValue(loader),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    const request = UseCalculatorRequest(id: 'calculator-1');
    container.listen(useCalculatorControllerProvider(request), (_, _) {});

    final state = await container.read(
      useCalculatorControllerProvider(request).future,
    );
    expect(state.calculator.name, 'BMI');
    expect(state.html, contains('<body>BMI</body>'));
    expect(loader.loaded?.id, 'calculator-1');

    container
        .read(useCalculatorControllerProvider(request).notifier)
        .webViewReady();
    expect(
      container
          .read(useCalculatorControllerProvider(request))
          .value!
          .isWebViewReady,
      isTrue,
    );
  });
}
