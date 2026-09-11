import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/app_skeleton.dart';

void main() {
  testWidgets('uses an accessible shimmer skeleton instead of a spinner', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLoadingView(message: 'Loading clinical guidance...'),
        ),
      ),
    );

    expect(find.byType(AppShimmer), findsOneWidget);
    expect(find.byType(AppSkeleton), findsNWidgets(11));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.bySemanticsLabel('Loading clinical guidance...'),
      findsOneWidget,
    );

    final shimmer = tester.widget<AppShimmer>(find.byType(AppShimmer));
    expect(shimmer.child, isNotNull);
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('honours reduced-motion accessibility settings', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AppLoadingView(),
        ),
      ),
    );

    expect(find.byType(AppShimmer), findsOneWidget);
    final skeleton = find.byType(AppSkeleton).first;
    final container = tester.widget<Container>(
      find.descendant(of: skeleton, matching: find.byType(Container)),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.gradient, isNull);
  });
}
