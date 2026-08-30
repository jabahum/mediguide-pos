import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/utils/app_message.dart';

void main() {
  test('feature code routes transient messages through AppMessage', () {
    final violations = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('core/utils/app_message.dart'))
        .where((file) {
          final source = file.readAsStringSync();
          return source.contains('ScaffoldMessenger.of(') ||
              source.contains('SnackBar(');
        })
        .map((file) => file.path)
        .toList();

    expect(
      violations,
      isEmpty,
      reason: 'Use AppMessage for transient user communication.',
    );
  });

  testWidgets('shows a typed message and replaces the current message', (
    tester,
  ) async {
    late BuildContext messageContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              messageContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    AppMessage.info(messageContext, 'First message');
    await tester.pump();
    expect(find.text('First message'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    AppMessage.error(messageContext, 'Replacement message');
    await tester.pumpAndSettle();
    expect(find.text('First message'), findsNothing);
    expect(find.text('Replacement message'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('runs a custom message action', (tester) async {
    late BuildContext messageContext;
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              messageContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    AppMessage.error(
      messageContext,
      'Unable to load.',
      actionLabel: 'RETRY',
      onAction: () => retried = true,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('RETRY'));
    expect(retried, isTrue);
  });
}
