import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/features/search/presentation/screens/global_search_page.dart';
import 'package:user_app/shared/models/search_models.dart';
import 'package:user_app/features/search/presentation/controllers/global_search_controller.dart';

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
    'a failed category does not suppress successful search categories',
    () async {
      final batches = await searchCategoriesIndependently(
        const [SearchCategory.outbreakDocuments, SearchCategory.drugs],
        (category) async {
          if (category == SearchCategory.outbreakDocuments) {
            throw StateError('document endpoint unavailable');
          }
          return const [
            SearchResult(
              id: 'drug-1',
              title: 'Aspirin',
              category: SearchCategory.drugs,
            ),
          ];
        },
      );

      expect(batches.first, isEmpty);
      expect(batches.last.single.title, 'Aspirin');
    },
  );

  testWidgets(
    'outbreak document results show source metadata, snippet and cache status',
    (tester) async {
      final dataSource = ControlledSearchDataSource();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            globalSearchDataSourceProvider.overrideWithValue(dataSource),
          ],
          child: const MaterialApp(home: GlobalSearchPage()),
        ),
      );

      await tester.enterText(find.byType(TextField), 'ebola');
      await tester.pump(const Duration(milliseconds: 400));
      dataSource.requests['ebola']!.complete(const [
        SearchResult(
          id: 'document-1',
          title: 'Ebola IPC SOP',
          subtitle:
              'Ebola response · ipc protocol · Ministry of Health · Version 2.0',
          description: 'Use PPE before entering the isolation area.',
          category: SearchCategory.outbreakDocuments,
          route: '/outbreak-hub/outbreak-1/documents/document-1',
          isOffline: true,
          isStale: true,
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Ebola IPC SOP'), findsOneWidget);
      expect(find.textContaining('Ministry of Health'), findsOneWidget);
      expect(find.textContaining('Use PPE'), findsOneWidget);
      expect(find.text('Offline cached result · may be stale'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an outbreak is presented as a top result and opens its hub', (
    tester,
  ) async {
    final dataSource = ControlledSearchDataSource();
    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(path: '/search', builder: (_, _) => const GlobalSearchPage()),
        GoRoute(
          path: '/outbreak-hub/:outbreakId',
          builder: (_, state) =>
              Text('Opened ${state.pathParameters['outbreakId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          globalSearchDataSourceProvider.overrideWithValue(dataSource),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(find.byType(TextField), 'ebola');
    await tester.pump(const Duration(milliseconds: 400));
    dataSource.requests['ebola']!.complete(const [
      SearchResult(
        id: 'guideline-1',
        title: 'General infection guideline',
        category: SearchCategory.guidelines,
        relevanceScore: 2,
      ),
      SearchResult(
        id: 'outbreak-1',
        title: 'Ebola response hub',
        subtitle: 'Ebola virus disease · Kasese District',
        category: SearchCategory.outbreaks,
        route: '/outbreak-hub/outbreak-1',
        relevanceScore: 10,
        item: PublicOutbreak(
          id: 'outbreak-1',
          title: 'Ebola response hub',
          diseaseType: 'Ebola virus disease',
          geographicArea: 'Kasese District',
          status: 'active',
        ),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Outbreaks · Top results'), findsOneWidget);
    expect(find.text('Active outbreak'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Ebola response hub')).dy,
      lessThan(tester.getTopLeft(find.text('General infection guideline')).dy),
    );

    await tester.tap(find.text('Ebola response hub'));
    await tester.pumpAndSettle();
    expect(find.text('Opened outbreak-1'), findsOneWidget);
  });

  testWidgets(
    'outbreak document search result opens the exact route with match metadata',
    (tester) async {
      final dataSource = ControlledSearchDataSource();
      const document = PublicOutbreakDocument(
        id: 'document-1',
        outbreakId: 'outbreak-1',
        title: 'Ebola IPC SOP',
        matchingHeading: 'Isolation procedure',
        matchingSectionId: 'isolation-procedure',
      );
      Object? routedExtra;
      final router = GoRouter(
        initialLocation: '/search',
        routes: [
          GoRoute(path: '/search', builder: (_, _) => const GlobalSearchPage()),
          GoRoute(
            path: '/outbreak-hub/:outbreakId/documents/:documentId',
            builder: (_, state) {
              routedExtra = state.extra;
              return Text(
                '${state.pathParameters['outbreakId']}/'
                '${state.pathParameters['documentId']}',
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            globalSearchDataSourceProvider.overrideWithValue(dataSource),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.enterText(find.byType(TextField), 'ebola');
      await tester.pump(const Duration(milliseconds: 400));
      dataSource.requests['ebola']!.complete(const [
        SearchResult(
          id: 'document-1',
          title: 'Ebola IPC SOP',
          category: SearchCategory.outbreakDocuments,
          route: '/outbreak-hub/outbreak-1/documents/document-1',
          item: document,
        ),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ebola IPC SOP'));
      await tester.pumpAndSettle();

      expect(find.text('outbreak-1/document-1'), findsOneWidget);
      expect(routedExtra, same(document));
      expect(
        (routedExtra! as PublicOutbreakDocument).matchingSectionId,
        'isolation-procedure',
      );
    },
  );

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
