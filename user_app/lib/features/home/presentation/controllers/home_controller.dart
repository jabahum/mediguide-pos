import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';

final class HomeState {
  const HomeState({
    this.continueReadingItems = const [],
    this.featuredCalculators = const [],
    this.pinnedGuidelines = const [],
    this.recentlyUpdatedGuidelines = const [],
    this.guidelineCategories = const [],
    this.unreadMessagesCount = 0,
    this.stats = const {},
  });

  final List<ReadingProgress> continueReadingItems;
  final List<Calculator> featuredCalculators;
  final List<Guideline> pinnedGuidelines;
  final List<Guideline> recentlyUpdatedGuidelines;
  final List<GuidelineCategory> guidelineCategories;
  final int unreadMessagesCount;
  final Map<String, int> stats;

  bool get hasContent =>
      continueReadingItems.isNotEmpty ||
      featuredCalculators.isNotEmpty ||
      recentlyUpdatedGuidelines.isNotEmpty;
}

final homeControllerProvider =
    AutoDisposeAsyncNotifierProvider<HomeController, HomeState>(
      HomeController.new,
    );

class HomeController extends AutoDisposeAsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading<HomeState>().copyWithPrevious(state);
    state = await AsyncValue.guard(_load);
  }

  Future<Guideline> guideline(String id) async {
    return ref.read(guidelineContentRepositoryProvider).guideline(id);
  }

  Future<HomeState> _load() async {
    final results = await Future.wait<dynamic>([
      _featuredCalculators(),
      _continueReading(),
      _categories(),
      _guidelines(),
      _stats(),
    ]);
    final guidelines = results[3] as List<Guideline>;
    final stats = results[4] as Map<String, int>;
    return HomeState(
      featuredCalculators: results[0] as List<Calculator>,
      continueReadingItems: results[1] as List<ReadingProgress>,
      guidelineCategories: results[2] as List<GuidelineCategory>,
      pinnedGuidelines: guidelines.take(5).toList(growable: false),
      recentlyUpdatedGuidelines: guidelines.take(5).toList(growable: false),
      unreadMessagesCount: stats['unread_messages_count'] ?? 0,
      stats: stats,
    );
  }

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
      final calculators = featured.items
          .map((calculator) => calculator)
          .toList(growable: true);
      if (calculators.length < 6) {
        final fallback = await repository.list(
          page: 1,
          perPage: 6 - calculators.length,
          statuses: const ['active'],
          featured: false,
          sort: 'usage_count',
          order: 'desc',
        );
        final existing = calculators.map((item) => item.id).toSet();
        calculators.addAll(
          fallback.items
              .map((calculator) => calculator)
              .where((item) => existing.add(item.id)),
        );
      }
      return calculators.take(6).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<ReadingProgress>> _continueReading() async {
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user == null) return const [];
    try {
      final result = await ref
          .read(readingProgressRepositoryProvider)
          .inProgress(user.id, perPage: 6);
      return result.items;
    } catch (_) {
      return const [];
    }
  }

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

  Future<Map<String, int>> _stats() async {
    try {
      final response = await ref
          .read(backendApiServiceProvider)
          .getCustomEndpoint(path: '/api/stats');
      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : response;
      const keys = [
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
