import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:user_app/features/home/presentation/controllers/home_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/abbreviations/data/repositories/abbreviation_local_repository.dart';
import 'package:user_app/features/calculators/data/repositories/calculator_local_repository.dart';
import 'package:user_app/features/calculators/data/repositories/calculator_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/guildline_content_local_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/guideline_content_repository.dart';
import 'helpers/test_local_store.dart';

List<Override> offlineRepositoryOverrides(HomeApi api, TestLocalStore store) =>
    [
      calculatorRepositoryProvider.overrideWithValue(
        CalculatorRepository(api, CalculatorLocalRepository(store.cache)),
      ),
      guidelineContentRepositoryProvider.overrideWithValue(
        GuidelineContentRepository(
          api,
          GuidelineContentLocalRepository(store.cache),
          AbbreviationLocalRepository(store.cache),
        ),
      ),
    ];

final class EmptySessionStore implements AuthSessionStore {
  @override
  User? currentUser;
  @override
  Future<bool> clearUser() async => true;
  @override
  Future<bool> saveUser(User user) async => true;
}

final class HomeApi extends BackendApiService {
  int guidelineRequests = 0;

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
    if (path == '/api/v2/calculators') {
      return {
        'data': {
          'items': [
            {'id': 'calculator-1', 'name': 'BMI', 'status': 'active'},
          ],
        },
      };
    }
    if (path == '/api/v2/guideline-categories') {
      return {
        'data': {
          'items': [
            {'id': 'category-1', 'name': 'Emergency', 'slug': 'emergency'},
          ],
        },
      };
    }
    if (path == '/api/v2/medical-guidelines') {
      guidelineRequests++;
      return {
        'data': {
          'items': [
            {
              'id': 'guideline-1',
              'name': 'Emergency care',
              'condition_name': 'Emergency care',
              'status': 'published',
            },
          ],
        },
      };
    }
    throw StateError('Unexpected request: $path');
  }

  @override
  Future<Map<String, dynamic>> getCustomEndpoint({
    required String path,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool forceRefresh = false,
  }) async {
    expect(path, '/api/stats');
    return {
      'data': {'unread_messages_count': 4, 'medical_guidelines': 1},
    };
  }
}

void main() {
  test('loads typed home data and unread message count', () async {
    final api = HomeApi();
    final store = TestLocalStore();
    addTearDown(store.close);
    final container = ProviderContainer(
      overrides: [
        backendApiServiceProvider.overrideWithValue(api),
        authSessionStoreProvider.overrideWithValue(EmptySessionStore()),
        ...offlineRepositoryOverrides(api, store),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);

    final state = await container.read(homeControllerProvider.future);

    expect(state.featuredCalculators.single.id, 'calculator-1');
    expect(state.recentlyUpdatedGuidelines.single.id, 'guideline-1');
    expect(state.guidelineCategories.single.id, 'category-1');
    expect(state.unreadMessagesCount, 4);
    expect(state.stats['medical_guidelines'], 1);
  });

  test('refresh replaces home state without duplicating records', () async {
    final api = HomeApi();
    final store = TestLocalStore();
    addTearDown(store.close);
    final container = ProviderContainer(
      overrides: [
        backendApiServiceProvider.overrideWithValue(api),
        authSessionStoreProvider.overrideWithValue(EmptySessionStore()),
        ...offlineRepositoryOverrides(api, store),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    await container.read(homeControllerProvider.future);

    await container.read(homeControllerProvider.notifier).refresh();

    final state = container.read(homeControllerProvider).value!;
    expect(state.featuredCalculators, hasLength(1));
    expect(state.recentlyUpdatedGuidelines, hasLength(1));
    expect(api.guidelineRequests, 2);
  });
}
