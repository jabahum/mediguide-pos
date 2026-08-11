import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/guidelines/presentation/widgets/clinical_callout.dart';

void main() {
  test('parses callout metadata and preserves clinical values exactly', () {
    final parts = parseGuidelineCallouts(
      ':::dosage title="Reviewed dose" severity=high evidence_grade=A\nGive 5 mg/kg.\n:::',
    );
    final callout = (parts.single as GuidelineCalloutPart).callout;
    expect(callout.type, 'dosage');
    expect(callout.title, 'Reviewed dose');
    expect(callout.content, 'Give 5 mg/kg.');
  });

  testWidgets('renders nested markup as inert text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalCalloutCard(
            callout: const ClinicalCalloutData(
              type: 'warning',
              content: '<script>alert(1)</script>',
            ),
          ),
        ),
      ),
    );
    expect(find.text('<script>alert(1)</script>'), findsOneWidget);
  });
}
