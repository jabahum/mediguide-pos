import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/home/presentation/screens/guest_home_page.dart';

void main() {
  testWidgets(
    'guest home remains usable on a narrow phone at 200% text scale',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guestHomePublicationsProvider.overrideWith(
              (ref) async => const [
                GuidelinePublication(
                  id: 'guideline-1',
                  title: 'Example published clinical guideline',
                  sourceOrganization: 'Example source organization',
                  programArea: 'Primary care',
                  version: '2',
                ),
              ],
            ),
          ],
          child: MaterialApp(
            builder: (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: const [
                Breakpoint(start: 0, end: 450, name: MOBILE),
                Breakpoint(start: 451, end: 800, name: TABLET),
                Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
              ],
            ),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 900),
                textScaler: TextScaler.linear(2),
              ),
              child: const GuestHomePage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trusted clinical guidance'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Example published clinical guideline'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Example published clinical guideline'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
