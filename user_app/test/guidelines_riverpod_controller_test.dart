import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/app/data/models/models.dart';
import 'package:user_app/app/data/repositories/guideline_content_repository.dart';
import 'package:user_app/app/data/services/backend_api_service.dart';
import 'package:user_app/app/features/auth/auth_controller.dart';
import 'package:user_app/app/features/auth/auth_session_store.dart';
import 'package:user_app/app/features/guidelines/read_guideline_controller.dart';
import 'package:user_app/app/modules/guidelines_module/guidelines_controller.dart';
import 'package:user_app/app/providers/core_providers.dart';

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
          'guideline_id': 'guideline-1',
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
    final controller = GuidelinesController(
      GuidelineContentRepository(GuidelineApi()),
      const {'filterType': 'tag', 'tagId': 'tag-1', 'title': 'Emergency care'},
    );
    addTearDown(controller.dispose);

    expect(controller.isInTagMode, isTrue);
    expect(controller.selectedTagId, 'tag-1');
    expect(controller.effectivePageTitle, 'Emergency care');
    expect(controller.hasPermanentFilter, isTrue);
  });

  test(
    'reader restores progress and sends owner-safe bookmark updates',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final api = GuidelineApi();
      final container = ProviderContainer(
        overrides: [
          backendApiServiceProvider.overrideWithValue(api),
          authSessionStoreProvider.overrideWithValue(TestSessionStore()),
          sharedPreferencesProvider.overrideWithValue(preferences),
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
    final guideline = Guideline({
      'id': 'guideline-1',
      'condition_name': 'Asthma',
      'medication_primary': 'Salbutamol',
      'dosage_adult': 'Two puffs',
    });

    expect(guidelineSections(guideline), contains(GuidelineSection.medication));
    final content = guidelineSectionContent(
      guideline,
      GuidelineSection.medication,
    );
    expect(content, contains('Primary Medication'));
    expect(content, contains('Two puffs'));
  });
}
