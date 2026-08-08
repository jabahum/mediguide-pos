import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/shared/widgets/copyright_terms_widget.dart';

void main() {
  test('detail route builders encode identifiers as URL locations', () {
    expect(
      AppRoutes.guideline('blood pressure'),
      '/guidelines/blood%20pressure',
    );
    expect(AppRoutes.calculator('bmi/child'), '/calculators/bmi%2Fchild');
    expect(
      AppRoutes.healthFacility('facility 1'),
      '/health-facilities/facility%201',
    );
  });

  testWidgets('copyright links wrap on narrow screens without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 220, child: CopyrightTermsWidget()),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
