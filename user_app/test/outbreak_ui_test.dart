import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/services/download_service.dart';
import 'package:user_app/features/documents/presentation/screens/document_reader_page.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/features/outbreaks/presentation/screens/outbreak_document_screens.dart';
import 'package:user_app/features/outbreaks/presentation/screens/outbreak_screens.dart';

import 'helpers/test_local_store.dart';

const _outbreak = PublicOutbreak(
  id: 'outbreak-1',
  title: 'Regional response update with a deliberately descriptive title',
  status: 'active',
  geographicArea: 'Northern and western border districts',
  visualTone: 'critical',
  metrics: [
    OutbreakMetric(
      key: 'contacts',
      label: 'Contacts followed up across affected districts',
      value: '836',
      unit: 'people',
    ),
  ],
);

class _OutbreakController extends PublicOutbreaksController {
  _OutbreakController(this.page);

  final PublicPage<PublicOutbreak> page;

  @override
  Future<PublicPage<PublicOutbreak>> build() async => page;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final configuration in <(String, Size, double, Brightness)>[
    ('narrow', const Size(320, 720), 1, Brightness.light),
    ('large', const Size(430, 932), 1, Brightness.light),
    ('tablet', const Size(800, 1180), 1, Brightness.light),
    ('text-200', const Size(390, 844), 2, Brightness.light),
    ('dark', const Size(390, 844), 1, Brightness.dark),
  ]) {
    testWidgets('outbreak hub is responsive at ${configuration.$1}', (
      tester,
    ) async {
      tester.view.physicalSize = configuration.$2;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final page = PublicPage(
        items: const [_outbreak],
        page: 1,
        perPage: 20,
        totalItems: 1,
        totalPages: 1,
        cache: PublicCacheMetadata(
          cachedAt: DateTime.utc(2026, 8, 1),
          lastVerifiedAt: DateTime.utc(2026, 8, 1),
          isStale: true,
          isWithdrawn: false,
          isOffline: true,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            publicOutbreaksProvider.overrideWith(
              () => _OutbreakController(page),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(brightness: configuration.$4),
            home: MediaQuery(
              data: MediaQueryData(
                size: configuration.$2,
                textScaler: TextScaler.linear(configuration.$3),
              ),
              child: const OutbreakHubPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Offline copy'), findsOneWidget);
      expect(find.byType(OutbreakHubPage), findsOneWidget);
    });
  }

  testWidgets('withdrawn outbreak has an explicit unavailable state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicOutbreakProvider('outbreak-1').overrideWith(
            (_) => Future<PublicContent<PublicOutbreakDetail>>.error(
              const PublicContentUnavailableException(
                'No longer public.',
                isWithdrawn: true,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: OutbreakDetailPage(outbreakId: 'outbreak-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Publication withdrawn'), findsOneWidget);
    expect(find.text('No longer public.'), findsOneWidget);
  });

  testWidgets('outbreak detail presents governed documents separately', (
    tester,
  ) async {
    const detail = PublicOutbreakDetail(
      outbreak: _outbreak,
      documents: [
        PublicOutbreakDocument(
          id: 'document-1',
          outbreakId: 'outbreak-1',
          title: 'Ebola response SOP',
          documentKind: 'ipc_protocol',
          issuingAuthority: 'Ministry of Health',
          version: '2.0',
          language: 'en',
          mimeType: 'application/pdf',
          fileSize: 4096,
          downloadUrl:
              '/api/public/outbreaks/outbreak-1/documents/document-1/download',
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicOutbreakProvider('outbreak-1').overrideWith(
            (_) async => const PublicContent(
              value: detail,
              cache: PublicCacheMetadata.online(),
            ),
          ),
        ],
        child: const MaterialApp(
          home: OutbreakDetailPage(outbreakId: 'outbreak-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Quick access'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Quick access'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('IPC & PPE'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('IPC & PPE'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ebola response SOP'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Official documents and SOPs'), findsOneWidget);
    expect(find.text('Ebola response SOP'), findsOneWidget);
    expect(find.text('Ipc Protocol'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'API-driven outbreak hub renders configured pillars without legacy content',
    (tester) async {
      const detail = PublicOutbreakDetail(outbreak: _outbreak);
      const hub = PublicOutbreakHub(
        id: 'hub-1',
        name: 'Regional response hub',
        slug: 'regional-response-hub',
        pillars: [
          PublicOutbreakPillar(
            id: 'pillar-1',
            name: 'Surveillance Guidance',
            slug: 'surveillance-guidance',
            description: 'Case finding and reporting guidance',
            icon: 'activity',
            color: '',
            items: [],
            children: [],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backendManagedOutbreakHubsEnabledProvider.overrideWithValue(true),
            publicOutbreakProvider('outbreak-1').overrideWith(
              (_) async => const PublicContent(
                value: detail,
                cache: PublicCacheMetadata.online(),
              ),
            ),
            publicOutbreakHubProvider(
              'outbreak-1',
            ).overrideWith((_) async => hub),
          ],
          child: const MaterialApp(
            home: OutbreakDetailPage(outbreakId: 'outbreak-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Surveillance Guidance'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Quick access'), findsOneWidget);
      expect(find.text('Surveillance Guidance'), findsOneWidget);
      expect(find.text('Clinical Care'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'guest outbreak hub opens the complete Clinical Care section workflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final documents = <PublicOutbreakDocument>[
        for (final kind in const [
          'case_definition',
          'sop',
          'treatment_protocol',
          'ipc_protocol',
          'referral_protocol',
          'laboratory_protocol',
          'policy',
          'contact_tracing_guide',
          'form',
          'checklist',
          'training_material',
          'communication_material',
          'other',
        ])
          PublicOutbreakDocument(
            id: 'document-$kind',
            outbreakId: 'outbreak-1',
            title: 'Published ${kind.replaceAll('_', ' ')}',
            documentKind: kind,
            supportsInline: true,
          ),
      ];
      final detail = PublicOutbreakDetail(
        outbreak: _outbreak.copyWith(diseaseType: 'Ebola Virus Disease'),
        documents: documents,
        reports: const [
          PublicSituationReport(
            id: 'report-1',
            outbreakId: 'outbreak-1',
            title: 'Situation report',
          ),
        ],
      );
      final router = GoRouter(
        initialLocation: '/outbreak-hub/outbreak-1',
        routes: [
          GoRoute(
            path: AppRoutes.outbreakDetails,
            builder: (_, state) => OutbreakDetailPage(
              outbreakId: state.pathParameters['outbreakId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.outbreakSection,
            builder: (_, state) => OutbreakSectionGridPage(
              outbreakId: state.pathParameters['outbreakId']!,
              sectionId: state.pathParameters['sectionId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.outbreakDocumentDetails,
            builder: (_, state) =>
                Text('Opened ${state.pathParameters['documentId']}'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            publicOutbreakProvider('outbreak-1').overrideWith(
              (_) async => PublicContent(
                value: detail,
                cache: const PublicCacheMetadata.online(),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Quick access'),
        220,
        scrollable: find.byType(Scrollable).last,
      );

      for (final label in const [
        'Clinical Care',
        'IPC & PPE',
        'Algorithms',
        'Laboratory',
        'Medicines',
        'Forms',
        'Training',
        'Situation reports',
        'Contacts',
        'FAQs',
      ]) {
        expect(find.text(label), findsAtLeastNWidgets(1));
      }

      await Scrollable.ensureVisible(
        tester.element(find.text('Clinical Care')),
        alignment: 0.5,
      );
      await tester.pump();
      await tester.tap(find.text('Clinical Care'));
      await tester.pumpAndSettle();
      expect(
        find.text('Evidence-based clinical management for Ebola Virus Disease'),
        findsOneWidget,
      );
      expect(find.text('Case Definition'), findsOneWidget);
      expect(find.text('Screening & Triage'), findsOneWidget);
      expect(find.text('Isolation'), findsOneWidget);
      expect(find.text('Clinical Management'), findsOneWidget);
      expect(find.text('Discharge Criteria'), findsOneWidget);
      expect(find.text('Follow-up & Monitoring'), findsOneWidget);

      await tester.tap(find.text('Case Definition'));
      await tester.pumpAndSettle();
      expect(find.text('Opened document-case_definition'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'outbreak Markdown reader exposes metadata, search, TOC and actions',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> action() async {}

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2),
            ),
            child: OutbreakMarkdownReaderPage(
              document: const PublicOutbreakDocument(
                id: 'document-1',
                outbreakId: 'outbreak-1',
                title: 'Ebola isolation SOP',
                issuingAuthority: 'Ministry of Health',
                version: '2.0',
              ),
              content: OutbreakDocumentContent(
                documentId: 'document-1',
                outbreakId: 'outbreak-1',
                title: 'Ebola isolation SOP',
                content:
                    '# Isolation\n\nNotify surveillance immediately.\n\n## Referral\n\nArrange safe referral.',
                sections: const [
                  OutbreakDocumentSection(
                    id: 'isolation',
                    heading: 'Isolation',
                    level: 1,
                  ),
                  OutbreakDocumentSection(
                    id: 'referral',
                    heading: 'Referral',
                    level: 2,
                  ),
                ],
                reviewDate: DateTime.utc(2026, 1, 1),
              ),
              cache: const PublicCacheMetadata(
                cachedAt: null,
                lastVerifiedAt: null,
                isStale: true,
                isWithdrawn: false,
                isOffline: true,
              ),
              onOpenOriginal: action,
              onSaveOffline: action,
              onShare: action,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ministry of Health'), findsOneWidget);
      expect(find.text('Version 2.0'), findsOneWidget);
      expect(find.textContaining('review date'), findsOneWidget);
      expect(find.text('Open original'), findsOneWidget);
      expect(find.text('Save offline'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);

      await tester.tap(find.byTooltip('Table of contents'));
      await tester.pumpAndSettle();
      expect(find.text('Table of contents'), findsOneWidget);
      expect(find.text('Referral'), findsWidgets);
      await tester.tap(find.text('Referral').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Search this document'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'surveillance');
      await tester.pumpAndSettle();
      expect(find.text('1/1'), findsOneWidget);
      expect(find.textContaining('surveillance'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Markdown reader moves to the section supplied by search', (
    tester,
  ) async {
    final filler = List.filled(80, 'Clinical preparation step.').join('\n\n');
    await tester.pumpWidget(
      MaterialApp(
        home: OutbreakMarkdownReaderPage(
          document: const PublicOutbreakDocument(
            id: 'document-1',
            outbreakId: 'outbreak-1',
            title: 'Ebola isolation SOP',
          ),
          content: OutbreakDocumentContent(
            documentId: 'document-1',
            outbreakId: 'outbreak-1',
            title: 'Ebola isolation SOP',
            content:
                '# Preparation\n\n$filler\n\n## Safe referral\n\nNotify now.',
            sections: const [
              OutbreakDocumentSection(
                id: 'safe-referral',
                heading: 'Safe referral',
                level: 2,
              ),
            ],
          ),
          cache: const PublicCacheMetadata.online(),
          matchingHeading: 'Safe referral',
          onOpenOriginal: _noop,
          onSaveOffline: _noop,
          onShare: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final markdown = find.byKey(const Key('outbreak-document-markdown'));
    final markdownScrollable = find.descendant(
      of: markdown,
      matching: find.byType(Scrollable),
    );
    final scrollable = tester.state<ScrollableState>(markdownScrollable.first);
    expect(scrollable.position.pixels, greaterThan(0));
    expect(find.text('Safe referral'), findsOneWidget);
  });

  testWidgets('PDF search match opens the reader at the matching page', (
    tester,
  ) async {
    final store = TestLocalStore();
    final downloads = GuidelineDownloadService(Dio(), store.cache);
    addTearDown(downloads.dispose);
    addTearDown(store.close);
    const document = PublicOutbreakDocument(
      id: 'document-1',
      outbreakId: 'outbreak-1',
      title: 'Ebola response report',
      mimeType: 'application/pdf',
      originalFilename: 'report.pdf',
      downloadUrl:
          '/api/public/outbreaks/outbreak-1/documents/document-1/download',
      matchingPdfPage: 7,
    );
    DocumentReaderArgs? readerArgs;
    final router = GoRouter(
      initialLocation: '/outbreak-hub/outbreak-1/documents/document-1',
      routes: [
        GoRoute(
          path: AppRoutes.outbreakDocumentDetails,
          builder: (_, state) => OutbreakDocumentPage(
            outbreakId: state.pathParameters['outbreakId']!,
            documentId: state.pathParameters['documentId']!,
            initialDocument: document,
          ),
        ),
        GoRoute(
          path: AppRoutes.documentReader,
          builder: (_, state) {
            readerArgs = state.extra! as DocumentReaderArgs;
            return Text('PDF page ${readerArgs!.initialPage}');
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    const key = (outbreakId: 'outbreak-1', documentId: 'document-1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guidelineDownloadServiceProvider.overrideWithValue(downloads),
          publicOutbreakDocumentProvider(key).overrideWith(
            (_) async => const PublicContent(
              value: document,
              cache: PublicCacheMetadata.online(),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PDF page 7'), findsOneWidget);
    expect(readerArgs?.initialPage, 7);
  });

  testWidgets(
    'document detail exposes loading, error and working retry states',
    (tester) async {
      final store = TestLocalStore();
      final downloads = GuidelineDownloadService(Dio(), store.cache);
      addTearDown(downloads.dispose);
      addTearDown(store.close);
      var attempts = 0;
      const key = (outbreakId: 'outbreak-1', documentId: 'document-1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guidelineDownloadServiceProvider.overrideWithValue(downloads),
            publicOutbreakDocumentProvider(key).overrideWith((_) async {
              attempts++;
              await Future<void>.delayed(const Duration(milliseconds: 20));
              if (attempts == 1) throw StateError('temporary failure');
              return const PublicContent(
                value: PublicOutbreakDocument(
                  id: 'document-1',
                  outbreakId: 'outbreak-1',
                  title: 'Recovered document',
                ),
                cache: PublicCacheMetadata.online(),
              );
            }),
          ],
          child: MaterialApp(
            builder: (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: const [
                Breakpoint(start: 0, end: 450, name: MOBILE),
                Breakpoint(start: 451, end: double.infinity, name: TABLET),
              ],
            ),
            home: const OutbreakDocumentPage(
              outbreakId: 'outbreak-1',
              documentId: 'document-1',
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Loading document...'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Document unavailable'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered document'), findsOneWidget);
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unsupported outbreak formats have an honest accessible state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OutbreakUnsupportedFormatNotice()),
      ),
    );

    expect(find.text('Inline preview unavailable'), findsOneWidget);
    expect(find.textContaining('authoritative original'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _noop() async {}
