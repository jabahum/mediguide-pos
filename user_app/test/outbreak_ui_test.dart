import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
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
}
