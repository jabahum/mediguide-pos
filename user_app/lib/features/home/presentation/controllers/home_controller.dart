// home_controller.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/home/presentation/controllers/home_state.dart';
import 'package:user_app/shared/models/models.dart';

part 'home_controller.g.dart';

@riverpod
class HomeController extends _$HomeController {
  @override
  Future<HomeState> build() {
    return _load();
  }

  // ======================================================
  // REFRESH
  // ======================================================

  Future<void> refresh() async {
    state = const AsyncLoading<HomeState>().copyWithPrevious(state);

    state = await AsyncValue.guard(_load);
  }

  // ======================================================
  // GUIDELINE LOOKUP
  // ======================================================

  Future<Guideline> guideline(String id) {
    return ref.read(guidelineContentRepositoryProvider).guideline(id);
  }

  // ======================================================
  // LOAD HOME DATA
  // ======================================================

  Future<HomeState> _load() async {
    final results = await Future.wait<dynamic>([
      _featuredCalculators(),
      _continueReading(),
      _categories(),
      _guidelines(),
      _stats(),
    ]);

    final featuredCalculators = results[0] as List<Calculator>;

    final continueReading = results[1] as List<ReadingProgress>;

    final categories = results[2] as List<GuidelineCategory>;

    final guidelines = results[3] as List<Guideline>;

    final stats = results[4] as Map<String, int>;

    return HomeState(
      featuredCalculators: List<Calculator>.unmodifiable(featuredCalculators),
      continueReadingItems: List<ReadingProgress>.unmodifiable(continueReading),
      guidelineCategories: List<GuidelineCategory>.unmodifiable(categories),
      pinnedGuidelines: List<Guideline>.unmodifiable(guidelines.take(5)),
      recentlyUpdatedGuidelines: List<Guideline>.unmodifiable(
        guidelines.take(5),
      ),
      unreadMessagesCount: stats['unread_messages_count'] ?? 0,
      stats: Map<String, int>.unmodifiable(stats),
    );
  }

  // ======================================================
  // FEATURED CALCULATORS
  // ======================================================

  Future<List<Calculator>> _featuredCalculators() async {
    try {
      final repository = ref.read(calculatorRepositoryProvider);

      final featured = await repository.list(
        page: 1,
        perPage: 6,
        statuses: const ['active'],
        featured: true,
        sort: 'usage_count',
        order: 'desc',
      );

      final calculators = <Calculator>[...featured.items];

      if (calculators.length < 6) {
        final fallback = await repository.list(
          page: 1,
          perPage: 6 - calculators.length,
          statuses: const ['active'],
          featured: false,
          sort: 'usage_count',
          order: 'desc',
        );

        final existingIds = calculators
            .map((calculator) => calculator.id)
            .toSet();

        calculators.addAll(
          fallback.items.where((calculator) => existingIds.add(calculator.id)),
        );
      }

      return calculators.take(6).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  // ======================================================
  // CONTINUE READING
  // ======================================================

  Future<List<ReadingProgress>> _continueReading() async {
    final user = ref.read(authControllerProvider).valueOrNull?.user;

    if (user == null) {
      return const [];
    }

    try {
      final result = await ref
          .read(readingProgressRepositoryProvider)
          .inProgress(user.id, perPage: 6);

      return result.items;
    } catch (_) {
      return const [];
    }
  }

  // ======================================================
  // CATEGORIES
  // ======================================================

  Future<List<GuidelineCategory>> _categories() async {
    try {
      final result = await ref
          .read(guidelineContentRepositoryProvider)
          .categories(perPage: 30, rootOnly: true);

      return result.items;
    } catch (_) {
      return const [];
    }
  }

  // ======================================================
  // GUIDELINES
  // ======================================================

  Future<List<Guideline>> _guidelines() async {
    try {
      final result = await ref
          .read(guidelineContentRepositoryProvider)
          .guidelines(perPage: 5, published: true, status: 'published');

      return result.items;
    } catch (_) {
      return const [];
    }
  }

  // ======================================================
  // STATS
  // ======================================================

  Future<Map<String, int>> _stats() async {
    try {
      final response = await ref
          .read(backendApiServiceProvider)
          .getCustomEndpoint(path: '/api/stats');

      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : response;

      const keys = <String>[
        'drugs',
        'medical_guidelines',
        'calculators',
        'abbreviations',
        'health_facilities',
        'consultants',
        'ministry_directory',
        'faqs',
        'user_conversations_count',
        'unread_messages_count',
      ];

      return {for (final key in keys) key: (data[key] as num?)?.toInt() ?? 0};
    } catch (_) {
      return const {};
    }
  }
}
