import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/calculators/presentation/controllers/use_calculator_controller.dart';

void main() {
  test('legacy calculator cache digest detects content changes', () {
    const original = '<html><head></head><body>reviewed</body></html>';
    const changed = '<html><head></head><body>changed</body></html>';

    expect(
      legacyCalculatorCacheDigest(original),
      isNot(legacyCalculatorCacheDigest(changed)),
    );
    expect(legacyCalculatorCacheValid(original), isTrue);
  });

  test('legacy calculator cache rejects oversized content', () {
    final oversized = '<html>${'x' * ((256 << 10) + 1)}</html>';
    expect(legacyCalculatorCacheValid(oversized), isFalse);
  });
}
