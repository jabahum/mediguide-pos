import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/app/data/models/search_models.dart';
import 'package:user_app/app/features/search/global_search_controller.dart';

final class ControlledSearchDataSource implements GlobalSearchDataSource {
  final requests = <String, Completer<List<SearchResult>>>{};

  @override
  Future<List<SearchResult>> search(String query) {
    return (requests[query] ??= Completer<List<SearchResult>>()).future;
  }
}

ProviderContainer createContainer(GlobalSearchDataSource dataSource) {
  final container = ProviderContainer(
    overrides: [globalSearchDataSourceProvider.overrideWithValue(dataSource)],
  );
  container.listen(globalSearchControllerProvider, (_, _) {});
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'validates empty and short queries without calling the data source',
    () async {
      final dataSource = ControlledSearchDataSource();
      final container = createContainer(dataSource);
      final controller = container.read(
        globalSearchControllerProvider.notifier,
      );

      await controller.search(' ');
      expect(container.read(globalSearchControllerProvider).query, isEmpty);

      await controller.search('a');
      final state = container.read(globalSearchControllerProvider);
      expect(state.validationMessage, 'Enter at least 2 characters');
      expect(state.results, isEmpty);
      expect(dataSource.requests, isEmpty);
    },
  );

  test('publishes successful results and count text', () async {
    final dataSource = ControlledSearchDataSource();
    final container = createContainer(dataSource);
    final controller = container.read(globalSearchControllerProvider.notifier);

    final pending = controller.search('aspirin');
    expect(container.read(globalSearchControllerProvider).isLoading, isTrue);
    dataSource.requests['aspirin']!.complete(const [
      SearchResult(
        id: 'drug-1',
        title: 'Aspirin',
        category: SearchCategory.drugs,
      ),
    ]);
    await pending;

    final state = container.read(globalSearchControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.results.single.title, 'Aspirin');
    expect(state.resultCountText, '1 result');
  });

  test('a late response cannot replace a newer query', () async {
    final dataSource = ControlledSearchDataSource();
    final container = createContainer(dataSource);
    final controller = container.read(globalSearchControllerProvider.notifier);

    final oldRequest = controller.search('old');
    final newRequest = controller.search('new');
    dataSource.requests['new']!.complete(const [
      SearchResult(
        id: 'new-1',
        title: 'New result',
        category: SearchCategory.guidelines,
      ),
    ]);
    await newRequest;
    dataSource.requests['old']!.complete(const [
      SearchResult(
        id: 'old-1',
        title: 'Old result',
        category: SearchCategory.guidelines,
      ),
    ]);
    await oldRequest;

    final state = container.read(globalSearchControllerProvider);
    expect(state.query, 'new');
    expect(state.results.single.id, 'new-1');
  });

  test('clear invalidates an in-flight request', () async {
    final dataSource = ControlledSearchDataSource();
    final container = createContainer(dataSource);
    final controller = container.read(globalSearchControllerProvider.notifier);

    final pending = controller.search('pending');
    controller.clear();
    dataSource.requests['pending']!.complete(const [
      SearchResult(
        id: 'late-1',
        title: 'Late result',
        category: SearchCategory.tools,
      ),
    ]);
    await pending;

    final state = container.read(globalSearchControllerProvider);
    expect(state.query, isEmpty);
    expect(state.results, isEmpty);
    expect(state.isLoading, isFalse);
  });
}
