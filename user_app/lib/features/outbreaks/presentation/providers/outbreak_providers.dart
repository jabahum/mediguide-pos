import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/features/outbreaks/data/repositories/outbreak_repository.dart';

final publicOutbreaksProvider =
    AsyncNotifierProvider.autoDispose<
      PublicOutbreaksController,
      PublicPage<PublicOutbreak>
    >(PublicOutbreaksController.new);

final publicOutbreakProvider = FutureProvider.autoDispose.family(
  (ref, String id) => ref.watch(outbreakRepositoryProvider).outbreak(id),
);

final publicSituationReportsProvider =
    AsyncNotifierProvider.autoDispose<
      PublicSituationReportsController,
      PublicPage<PublicSituationReport>
    >(PublicSituationReportsController.new);

final publicSituationReportProvider = FutureProvider.autoDispose.family(
  (ref, String id) => ref.watch(outbreakRepositoryProvider).report(id),
);

class PublicOutbreaksController
    extends AutoDisposeAsyncNotifier<PublicPage<PublicOutbreak>> {
  OutbreakQuery _query = const OutbreakQuery();

  @override
  Future<PublicPage<PublicOutbreak>> build() async {
    final enabled = ref.watch(outbreakFeatureEnabledProvider);
    if (!enabled) return _emptyOutbreakPage();
    return ref.watch(outbreakRepositoryProvider).outbreaks(query: _query);
  }

  Future<void> applyQuery(OutbreakQuery query) async {
    _query = query;
    state = const AsyncLoading<PublicPage<PublicOutbreak>>().copyWithPrevious(
      state,
    );
    state = await AsyncValue.guard(
      () => ref.read(outbreakRepositoryProvider).outbreaks(query: _query),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading<PublicPage<PublicOutbreak>>().copyWithPrevious(
      state,
    );
    state = await AsyncValue.guard(
      () =>
          ref.read(outbreakRepositoryProvider).refreshOutbreaks(query: _query),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || state.isLoading) return;
    final next = await ref
        .read(outbreakRepositoryProvider)
        .outbreaks(
          page: current.page + 1,
          perPage: current.perPage,
          query: _query,
        );
    state = AsyncData(
      PublicPage(
        items: [...current.items, ...next.items],
        page: next.page,
        perPage: next.perPage,
        totalItems: next.totalItems,
        totalPages: next.totalPages,
        cache: next.cache,
      ),
    );
  }
}

class PublicSituationReportsController
    extends AutoDisposeAsyncNotifier<PublicPage<PublicSituationReport>> {
  SituationReportQuery _query = const SituationReportQuery();

  @override
  Future<PublicPage<PublicSituationReport>> build() async {
    final enabled = ref.watch(outbreakFeatureEnabledProvider);
    if (!enabled) return _emptyReportPage();
    return ref.watch(outbreakRepositoryProvider).reports(query: _query);
  }

  Future<void> applyQuery(SituationReportQuery query) async {
    _query = query;
    state = const AsyncLoading<PublicPage<PublicSituationReport>>()
        .copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(outbreakRepositoryProvider).reports(query: _query),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading<PublicPage<PublicSituationReport>>()
        .copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(outbreakRepositoryProvider).refreshReports(query: _query),
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || state.isLoading) return;
    final next = await ref
        .read(outbreakRepositoryProvider)
        .reports(
          page: current.page + 1,
          perPage: current.perPage,
          query: _query,
        );
    state = AsyncData(
      PublicPage(
        items: [...current.items, ...next.items],
        page: next.page,
        perPage: next.perPage,
        totalItems: next.totalItems,
        totalPages: next.totalPages,
        cache: next.cache,
      ),
    );
  }
}

PublicPage<PublicOutbreak> _emptyOutbreakPage() => const PublicPage(
  items: <PublicOutbreak>[],
  page: 1,
  perPage: 20,
  totalItems: 0,
  totalPages: 0,
  cache: PublicCacheMetadata.online(),
);

PublicPage<PublicSituationReport> _emptyReportPage() => const PublicPage(
  items: <PublicSituationReport>[],
  page: 1,
  perPage: 20,
  totalItems: 0,
  totalPages: 0,
  cache: PublicCacheMetadata.online(),
);

/// Monitoring items remain visible in the response hub, but only an active
/// publication may occupy the high-priority home banner.
PublicOutbreak? selectPrimaryOutbreak(Iterable<PublicOutbreak> items) {
  final active = items.where((item) => item.status == 'active').toList()
    ..sort((left, right) {
      final leftDate =
          left.lastUpdate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightDate =
          right.lastUpdate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightDate.compareTo(leftDate);
    });
  return active.isEmpty ? null : active.first;
}
