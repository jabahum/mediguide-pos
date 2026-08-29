import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_state.dart';
import 'package:user_app/features/navigation/presentation/screens/main_page.dart';

final class _GuestAuthController extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.unauthenticated();
}

void main() {
  testWidgets('general assistant FAB remains on every guest bottom-nav tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_GuestAuthController.new),
        ],
        child: MaterialApp(
          builder: (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: const [
              Breakpoint(start: 0, end: 450, name: MOBILE),
              Breakpoint(start: 451, end: double.infinity, name: TABLET),
            ],
          ),
          home: const MainPage(),
        ),
      ),
    );
    await tester.pump();

    final assistant = find.byKey(const Key('global-ai-assistant-fab'));
    expect(assistant, findsOneWidget);

    final destinations = find.byType(NavigationDestination);
    expect(destinations, findsNWidgets(5));
    for (var index = 0; index < 5; index++) {
      await tester.tap(destinations.at(index));
      await tester.pump();
      expect(assistant, findsOneWidget);
    }
  });
}
