import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/features/outbreaks/presentation/screens/outbreak_document_screens.dart';
import 'package:user_app/features/outbreaks/presentation/screens/outbreak_screens.dart';

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

    expect(find.text('Official documents and SOPs'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ebola response SOP'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Ebola response SOP'), findsOneWidget);
    expect(find.text('Ipc Protocol'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
