import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/app/router/route_names.dart';

void main() {
  group('AppRoutes', () {
    test('recognizes published guideline deep links as public', () {
      expect(
        AppRoutes.isPublic('/public/guidelines/guideline-1?section=diagnosis'),
        isTrue,
      );
      expect(AppRoutes.isPublic('/profile'), isFalse);
    });

    test('accepts only safe local post-authentication destinations', () {
      expect(
        AppRoutes.safeDestination('/public/guidelines/guideline-1'),
        '/public/guidelines/guideline-1',
      );
      expect(
        AppRoutes.safeDestination('https://attacker.test'),
        AppRoutes.main,
      );
      expect(AppRoutes.safeDestination('//attacker.test'), AppRoutes.main);
      expect(AppRoutes.safeDestination(AppRoutes.login), AppRoutes.main);
    });
  });
}
