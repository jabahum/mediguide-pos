import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/calculators/presentation/screens/tools_page.dart';

void main() {
  testWidgets('renders the reference-aligned tools hub', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ToolsPage())),
    );

    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Clinical Tools'), findsOneWidget);
    expect(find.text('Calculators'), findsOneWidget);
    expect(find.text('Decision Tools'), findsOneWidget);
    expect(find.text('Checklists'), findsOneWidget);
    expect(find.text('References'), findsOneWidget);
    expect(find.text('Drug Index'), findsOneWidget);
    expect(find.text('Abbreviations'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Health Facilities'), findsOneWidget);
    expect(find.text('Ministry Directory'), findsOneWidget);
  });
}
