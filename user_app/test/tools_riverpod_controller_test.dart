import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/features/calculators/data/repositories/calculator_repository.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:user_app/features/calculators/presentation/controllers/use_calculator_controller.dart';
import 'package:user_app/features/calculators/presentation/controllers/tools_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/calculators/data/repositories/calculator_local_repository.dart';
import 'helpers/test_local_store.dart';

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
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = CalculatorRepository(
      ToolApi(),
      CalculatorLocalRepository(store.cache),
    );
    const arguments = {'initialTab': 2};
    final provider = toolsControllerProvider(arguments);
    final container = ProviderContainer(
      overrides: [calculatorRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(provider, (_, _) {});
    final state = container.read(provider);

    expect(state.selectedTabIndex, 2);
    expect(state.hasActiveFilters, isTrue);
  });

  test('calculator runner resolves an id and exposes loaded HTML', () async {
    final api = ToolApi();
    final loader = MemoryCalculatorLoader();
    final store = TestLocalStore();
    addTearDown(store.close);
    final container = ProviderContainer(
      overrides: [
        backendApiServiceProvider.overrideWithValue(api),
        authSessionStoreProvider.overrideWithValue(EmptyToolSessionStore()),
        calculatorContentLoaderProvider.overrideWithValue(loader),
        calculatorRepositoryProvider.overrideWithValue(
          CalculatorRepository(api, CalculatorLocalRepository(store.cache)),
        ),
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
