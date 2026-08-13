import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:user_app/core/widgets/app_error_view.dart';

void main() {
  testWidgets('local database failures do not expose raw SQL to users', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: const [
            Breakpoint(start: 0, end: 450, name: MOBILE),
            Breakpoint(start: 451, end: double.infinity, name: TABLET),
          ],
        ),
        home: const Scaffold(
          body: AppErrorView(
            error: 'SqliteException(1): no such table: cached_entities',
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Offline content could not be prepared'),
      findsOneWidget,
    );
    expect(find.textContaining('cached_entities'), findsNothing);
    expect(find.textContaining('SqliteException'), findsNothing);
  });
}
