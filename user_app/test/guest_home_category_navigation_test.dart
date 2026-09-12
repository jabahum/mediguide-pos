import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/guidelines/presentation/screens/publication_catalogue_page.dart';
import 'package:user_app/features/home/presentation/screens/guest_home_page.dart';

void main() {
  testWidgets('guest category opens its filtered publication catalogue', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const GuestHomePage()),
        GoRoute(
          path: AppRoutes.publicGuidelines,
          builder: (_, state) => PublicationCataloguePage(
            programArea: state.uri.queryParameters['program_area'] ?? '',
            categoryId: state.uri.queryParameters['category_id'] ?? '',
            categoryName: state.uri.queryParameters['category_name'] ?? '',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          outbreakFeatureEnabledProvider.overrideWithValue(false),
          guestHomePublicationsProvider.overrideWith(
            (_) async => const [
              GuidelinePublication(
                id: 'guideline-1',
                title: 'Primary care guideline',
                programArea: 'Primary care',
                categories: [
                  PublicationCategory(
                    id: 'primary-care-id',
                    name: 'Primary care',
                  ),
                ],
                version: '1',
              ),
            ],
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: const [
              Breakpoint(start: 0, end: 450, name: MOBILE),
              Breakpoint(start: 451, end: double.infinity, name: TABLET),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final categoryButton = find.byKey(
      const ValueKey('guest-category-Primary care'),
    );
    expect(categoryButton, findsOneWidget);
    tester.widget<InkWell>(categoryButton).onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Primary care Guidelines'), findsOneWidget);
    expect(find.text('Published guidance in Primary care'), findsOneWidget);
  });
}
