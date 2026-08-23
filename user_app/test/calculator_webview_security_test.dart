import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/calculators/presentation/screens/use_calculator_page.dart';

void main() {
  group('calculator WebView navigation policy', () {
    const base = 'https://api.mediguide.test/api/v2/calculators/';

    test('allows only the inert WebView bootstrap document', () {
      expect(calculatorNavigationAllowed('about:blank', base), isTrue);
    });

    test('blocks external origins and unsafe schemes', () {
      expect(
        calculatorNavigationAllowed('https://example.org/collect', base),
        isFalse,
      );
      expect(calculatorNavigationAllowed('javascript:alert(1)', base), isFalse);
      expect(
        calculatorNavigationAllowed('file:///tmp/tool.html', base),
        isFalse,
      );
      expect(calculatorNavigationAllowed('tel:+256700000000', base), isFalse);
      expect(
        calculatorNavigationAllowed('data:text/plain,calculator', base),
        isFalse,
      );
      expect(
        calculatorNavigationAllowed('blob:https://api.mediguide.test/id', base),
        isFalse,
      );
      expect(calculatorNavigationAllowed('${base}style.css', base), isFalse);
    });
  });
}
