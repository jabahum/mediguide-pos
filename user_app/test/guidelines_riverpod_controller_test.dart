import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/features/guidelines/data/repositories/guideline_content_repository.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:user_app/features/guidelines/presentation/controllers/read_guideline_controller.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/abbreviations/data/repositories/abbreviation_local_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/guildline_content_local_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/progress_usage_repository.dart';
import 'helpers/test_local_store.dart';

final class TestSessionStore implements AuthSessionStore {
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

final class GuidelineApi extends BackendApiService {
  Map<String, dynamic>? lastProgressBody;

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
        'data': {
          'id': 'user-1',
          'name': 'Clinical User',
          'email': 'clinical@example.com',
        },
      };
    }
    if (path == '/api/v2/medical-guidelines/guideline-1') {
      return {
        'data': {
          'id': 'guideline-1',
          'condition_name': 'Asthma',
          'definition': '<p>Airway inflammation</p>',
          'causes': '<p>Triggers</p>',
          'status': 'published',
          'is_published': true,
        },
      };
    }
    if (path == '/api/v2/reading-progress/guideline-1' && method == 'GET') {
      return {
        'data': {
          'id': 'progress-1',
          'user_id': 'user-1',
          'guideline_document_id': 'guideline-1',
          'current_section': 'causes',
          'progress_percentage': 0.4,
          'is_bookmarked': false,
        },
      };
    }
    if (path == '/api/v2/reading-progress/guideline-1' && method == 'PUT') {
      lastProgressBody = body;
      return {
        'data': {
          'id': 'progress-1',
          'user_id': 'user-1',
          'guideline_id': 'guideline-1',
          'current_section': 'causes',
          'progress_percentage': 0.4,
          ...?body,
        },
      };
    }
    if (path == '/api/v2/usage/guidelines') return {'data': {}};
    if (path == '/api/v2/guideline-categories') {
      return {
        'data': {'items': <Map<String, dynamic>>[]},
      };
    }
    if (path == '/api/v2/guideline-tags') {
      return {
        'data': {'items': <Map<String, dynamic>>[]},
      };
    }
    throw StateError('Unexpected request: $method $path');
  }
}

void main() {
  test('catalogue route arguments become typed permanent filters', () {
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = GuidelineContentRepository(
      GuidelineApi(),
      GuidelineContentLocalRepository(store.cache),
      AbbreviationLocalRepository(store.cache),
    );
    const arguments = {
      'filterType': 'tag',
      'tagId': 'tag-1',
      'title': 'Emergency care',
    };
    final provider = guidelinesControllerProvider(arguments);
    final container = ProviderContainer(
      overrides: [
        guidelineContentRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(provider, (_, _) {});
    final state = container.read(provider);

    expect(state.isInTagMode, isTrue);
    expect(state.route.selectedTagId, 'tag-1');
    expect(state.effectivePageTitle, 'Emergency care');
    expect(state.hasPermanentFilter, isTrue);
  });

  test(
    'reader restores progress and sends owner-safe bookmark updates',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final api = GuidelineApi();
      final store = TestLocalStore();
      addTearDown(store.close);
      final contentRepository = GuidelineContentRepository(
        api,
        GuidelineContentLocalRepository(store.cache),
        AbbreviationLocalRepository(store.cache),
      );
      final container = ProviderContainer(
        overrides: [
          backendApiServiceProvider.overrideWithValue(api),
          authSessionStoreProvider.overrideWithValue(TestSessionStore()),
          sharedPreferencesProvider.overrideWithValue(preferences),
          guidelineContentRepositoryProvider.overrideWithValue(
            contentRepository,
          ),
          readingProgressRepositoryProvider.overrideWithValue(
            ReadingProgressRepository(api, store.cache),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      const request = ReadGuidelineRequest(id: 'guideline-1');
      container.listen(readGuidelineControllerProvider(request), (_, _) {});

      final state = await container.read(
        readGuidelineControllerProvider(request).future,
      );
      expect(state.guideline.conditionName, 'Asthma');
      expect(state.sections, [
        GuidelineSection.definition,
        GuidelineSection.causes,
      ]);
      expect(state.currentSection, 'causes');
      expect(state.progressPercentage, 0.4);

      final changed = await container
          .read(readGuidelineControllerProvider(request).notifier)
          .toggleBookmark();
      expect(changed, isTrue);
      expect(api.lastProgressBody, containsPair('is_bookmarked', true));
      expect(api.lastProgressBody, isNot(contains('user_id')));
      expect(
        container
            .read(readGuidelineControllerProvider(request))
            .value!
            .isBookmarked,
        isTrue,
      );
    },
  );

  test('section content combines structured medication fields', () {
    const guideline = Guideline(
      id: 'guideline-1',
      conditionName: 'Asthma',
      medicationPrimary: 'Salbutamol',
      dosageAdult: 'Two puffs',
    );

    expect(guidelineSections(guideline), contains(GuidelineSection.medication));
    final content = guidelineSectionContent(
      guideline,
      GuidelineSection.medication,
    );
    expect(content, contains('Primary Medication'));
    expect(content, contains('Two puffs'));
  });
}
