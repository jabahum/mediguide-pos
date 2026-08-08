import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/content/data/repositories/content_reference_repository.dart';
import 'package:user_app/features/facilities/data/repositories/facility_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/guideline_content_repository.dart';
import 'package:user_app/features/support/data/repositories/help_content_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/progress_usage_repository.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/content/data/models/generic_page.dart';
import 'package:user_app/features/abbreviations/presentation/controllers/abbreviations_controller.dart';
import 'package:user_app/features/all_actions/presentation/controllers/all_actions_controller.dart';
import 'package:user_app/features/support/presentation/controllers/faq_controller.dart';
import 'package:user_app/features/content/presentation/controllers/generic_viewer_controller.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_indexer_controller.dart';
import 'package:user_app/features/content/presentation/controllers/ministry_directory_controller.dart';
import 'package:user_app/features/tree_selector/data/models/tree_selector_models.dart';
import 'package:user_app/features/tree_selector/presentation/controllers/tree_selector_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/abbreviations/data/repositories/abbreviation_local_repository.dart';
import 'package:user_app/features/content/data/repositories/generic_page_local_repository.dart';
import 'package:user_app/features/content/data/repositories/ministry_directory_local_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/guildline_content_local_repository.dart';
import 'package:user_app/features/support/data/repositories/help_content_local_repository.dart';
import 'helpers/test_local_store.dart';

class RemainingFeaturesApi extends BackendApiService {
  final List<String> paths = [];

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    paths.add(path);
    if (path == '/api/v2/pages') {
      return _page([
        {
          'id': 'page-1',
          'key': 'privacy',
          'title': 'Privacy',
          'description': 'Privacy information',
          'content': {'content': '<p>Privacy</p>'},
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        },
      ]);
    }
    if (path == '/api/v2/guideline-index') {
      return _page([
        {
          'id': 'root-1',
          'title': 'Clinical Care',
          'description': 'Root',
          'level': 0,
          'sort_order': 1,
        },
        {
          'id': 'child-1',
          'parent_id': 'root-1',
          'title': 'Emergency Care',
          'description': 'Child',
          'level': 1,
          'sort_order': 1,
        },
      ]);
    }
    if (path == '/api/v2/guideline-categories' ||
        path == '/api/v2/guideline-tags') {
      return _page(const []);
    }
    if (path == '/api/v2/districts') {
      return _page([
        {'id': 'district-1', 'name': 'Kampala'},
      ]);
    }
    if (path == '/api/v2/regions') {
      return _page([
        {'id': 'region-1', 'name': 'Central'},
      ]);
    }
    return _page(const []);
  }

  @override
  Future<Map<String, dynamic>> getCustomEndpoint({
    required String path,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool forceRefresh = false,
  }) async {
    paths.add(path);
    return {
      'success': true,
      'data': [
        {
          'id': 'region-1',
          'title': 'Central',
          'level': 0,
          'hasChildren': false,
          'filters': {'region': 'region-1'},
        },
      ],
    };
  }

  static Map<String, dynamic> _page(List<Map<String, dynamic>> items) => {
    'data': {
      'items': items,
      'page': 1,
      'per_page': 100,
      'total_items': items.length,
      'total_pages': items.isEmpty ? 0 : 1,
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FAQ notifier owns search state without a route binding', () {
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = HelpContentRepository(
      RemainingFeaturesApi(),
      HelpContentLocalRepository(store.cache),
    );
    final container = ProviderContainer(
      overrides: [helpContentRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(faqControllerProvider, (_, _) {});
    final controller = container.read(faqControllerProvider.notifier);

    controller.searchFAQs('malaria');
    expect(container.read(faqControllerProvider).searchQuery, 'malaria');
    expect(container.read(faqControllerProvider).hasActiveFilters, isTrue);

    controller.clearAllFilters();
    expect(container.read(faqControllerProvider).hasActiveFilters, isFalse);
  });

  test('abbreviation notifier loads typed taxonomy and owns filters', () async {
    final api = RemainingFeaturesApi();
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = GuidelineContentRepository(
      api,
      GuidelineContentLocalRepository(store.cache),
      AbbreviationLocalRepository(store.cache),
    );
    final container = ProviderContainer(
      overrides: [
        guidelineContentRepositoryProvider.overrideWithValue(repository),
        usageRepositoryProvider.overrideWithValue(UsageRepository(api)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(abbreviationsControllerProvider, (_, _) {});
    final controller = container.read(abbreviationsControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    controller.search('BP');
    expect(container.read(abbreviationsControllerProvider).query.search, 'BP');
    expect(api.paths, contains('/api/v2/guideline-categories'));
    expect(api.paths, contains('/api/v2/guideline-tags'));
  });

  test(
    'directory notifier restores route filters and typed metadata',
    () async {
      final api = RemainingFeaturesApi();
      final store = TestLocalStore();
      addTearDown(store.close);
      final container = ProviderContainer(
        overrides: [
          facilityRepositoryProvider.overrideWithValue(FacilityRepository(api)),
          ministryDirectoryRepositoryProvider.overrideWithValue(
            MinistryDirectoryRepository(
              api,
              MinistryDirectoryLocalRepository(store.cache),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(ministryDirectoryControllerProvider, (_, _) {});
      final controller = container.read(
        ministryDirectoryControllerProvider.notifier,
      );
      controller.applyTreeFilters({
        'region': 'Central',
        'district': 'Kampala',
        'emergency_only': true,
      });
      await controller.reloadFilterOptions();

      final state = container.read(ministryDirectoryControllerProvider);
      expect(state.query.selectedRegion, 'Central');
      expect(state.query.selectedDistrict, 'Kampala');
      expect(state.query.showEmergencyOnly, isTrue);
      expect(state.hasActiveFilters, isTrue);
      expect(api.paths, contains('/api/v2/regions'));
    },
  );

  test('generic page and action notifiers use focused repositories', () async {
    final api = RemainingFeaturesApi();
    final page = GenericPage(
      id: 'page-1',
      title: 'Privacy',
      key: 'privacy',
      content: const {'content': '<p>Privacy</p>'},
      created: DateTime(2026),
      updated: DateTime(2026),
    );
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = GenericPageRepository(
      api,
      GenericPageLocalRepository(store.cache),
    );
    final container = ProviderContainer(
      overrides: [genericPageRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(genericViewerControllerProvider, (_, _) {});
    container.listen(allActionsControllerProvider, (_, _) {});
    final viewer = container.read(genericViewerControllerProvider.notifier);

    await viewer.initialize(pageArgument: page);
    await Future<void>.delayed(Duration.zero);

    final viewerState = container.read(genericViewerControllerProvider);
    expect(viewerState.pageTitle, 'Privacy');
    expect(viewerState.hasContent, isTrue);
    expect(
      container.read(allActionsControllerProvider).genericPages.single.title,
      'Privacy',
    );
  });

  test(
    'guideline index and tree selector load without service locators',
    () async {
      final api = RemainingFeaturesApi();
      final store = TestLocalStore();
      addTearDown(store.close);
      final repository = GuidelineContentRepository(
        api,
        GuidelineContentLocalRepository(store.cache),
        AbbreviationLocalRepository(store.cache),
      );
      const config = TreeSelectorConfig(
        title: 'Select region',
        endpointPath: '/api/v2/tree',
      );
      final selectorProvider = treeSelectorControllerProvider(config);
      final container = ProviderContainer(
        overrides: [
          backendApiServiceProvider.overrideWithValue(api),
          guidelineContentRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      container.listen(guidelinesIndexerControllerProvider, (_, _) {});
      container.listen(selectorProvider, (_, _) {});
      final indexer = container.read(
        guidelinesIndexerControllerProvider.notifier,
      );

      await indexer.initialize(channel: 'Clinical');
      await Future<void>.delayed(Duration.zero);

      final indexState = container.read(guidelinesIndexerControllerProvider);
      final selectorState = container.read(selectorProvider);
      expect(indexState.hasLoadError, isFalse);
      expect(indexState.totalSections, 2);
      expect(indexState.visibleTree.childrenAsList, isNotEmpty);
      expect(selectorState.rootTreeNode.childrenAsList, hasLength(1));
      expect(api.paths, contains('/api/v2/tree'));
    },
  );
}
