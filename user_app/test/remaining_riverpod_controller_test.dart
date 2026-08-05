import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('FAQ notifier owns search state without a route binding', () {
    final controller = FaqController(
      HelpContentRepository(RemainingFeaturesApi()),
    );
    addTearDown(controller.dispose);

    controller.searchFAQs('malaria');
    expect(controller.searchQuery, 'malaria');
    expect(controller.hasActiveFilters, isTrue);

    controller.clearAllFilters();
    expect(controller.hasActiveFilters, isFalse);
  });

  test('abbreviation notifier loads typed taxonomy and owns filters', () async {
    final api = RemainingFeaturesApi();
    final controller = AbbreviationsController(
      UsageRepository(api),
      GuidelineContentRepository(api),
      canTrackUsage: true,
    );
    addTearDown(controller.dispose);
    await Future<void>.delayed(Duration.zero);

    controller.search('BP');
    expect(controller.query.search, 'BP');
    expect(api.paths, contains('/api/v2/guideline-categories'));
    expect(api.paths, contains('/api/v2/guideline-tags'));
  });

  test(
    'directory notifier restores route filters and typed metadata',
    () async {
      final api = RemainingFeaturesApi();
      final controller = MinistryDirectoryController(
        FacilityRepository(api),
        MinistryDirectoryRepository(api),
      );
      addTearDown(controller.dispose);
      controller.applyTreeFilters({
        'region': 'Central',
        'district': 'Kampala',
        'emergency_only': true,
      });
      await Future<void>.delayed(Duration.zero);

      expect(controller.selectedRegion, 'Central');
      expect(controller.selectedDistrict, 'Kampala');
      expect(controller.showEmergencyOnly, isTrue);
      expect(controller.hasActiveFilters, isTrue);
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
    final viewer = GenericViewerController(GenericPageRepository(api));
    final actions = AllActionsController(GenericPageRepository(api));
    addTearDown(viewer.dispose);
    addTearDown(actions.dispose);

    await viewer.initialize(pageArgument: page);
    await Future<void>.delayed(Duration.zero);

    expect(viewer.pageTitle, 'Privacy');
    expect(viewer.hasContent, isTrue);
    expect(actions.genericPages.single.title, 'Privacy');
  });

  test(
    'guideline index and tree selector load without service locators',
    () async {
      final api = RemainingFeaturesApi();
      final indexer = GuidelinesIndexerController(
        GuidelineContentRepository(api),
      );
      final selector = TreeSelectorController(
        const TreeSelectorConfig(
          title: 'Select region',
          endpointPath: '/api/v2/tree',
        ),
        api,
      );
      addTearDown(indexer.dispose);
      addTearDown(selector.dispose);

      await indexer.initialize(channel: 'Clinical');
      await Future<void>.delayed(Duration.zero);

      expect(indexer.hasLoadError, isFalse);
      expect(indexer.totalSections, 2);
      expect(indexer.visibleTree.childrenAsList, isNotEmpty);
      expect(selector.rootTreeNode.childrenAsList, hasLength(1));
      expect(api.paths, contains('/api/v2/tree'));
    },
  );
}
