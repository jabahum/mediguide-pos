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

    test('builds an encoded public programme-area catalogue route', () {
      final route = AppRoutes.publicGuidelinesForProgramArea(
        'Maternal & Child Health',
      );

      expect(
        route,
        '/public/guidelines?program_area=Maternal+%26+Child+Health',
      );
      expect(
        Uri.parse(route).queryParameters['program_area'],
        'Maternal & Child Health',
      );
      expect(AppRoutes.isPublic(route), isTrue);
    });

    test('recognizes outbreak clinical section deep links as public', () {
      final route = AppRoutes.outbreakSectionFor('outbreak-1', 'clinical-care');

      expect(route, '/outbreak-hub/outbreak-1/sections/clinical-care');
      expect(AppRoutes.isPublic(route), isTrue);
    });

    test('builds public disease, hub and nested pillar routes', () {
      expect(AppRoutes.disease('Ebola care'), '/diseases/Ebola%20care');
      expect(AppRoutes.hub('ebola-response'), '/hubs/ebola-response');
      expect(
        AppRoutes.hubPillar('ebola-response', 'IPC & PPE'),
        '/hubs/ebola-response/pillars/IPC%20%26%20PPE',
      );
      expect(AppRoutes.isPublic(AppRoutes.disease('ebola')), isTrue);
      expect(AppRoutes.isPublic(AppRoutes.hub('ebola-response')), isTrue);
      expect(
        AppRoutes.isPublic(
          AppRoutes.hubPillar('ebola-response', 'clinical-care'),
        ),
        isTrue,
      );
    });

    test('allows guests to open the general MediGuide Assistant', () {
      expect(AppRoutes.isPublic(AppRoutes.aiAssistant), isTrue);
    });

    test('builds encoded, authenticated collection routes', () {
      final route = AppRoutes.collection('ward rounds/2026');

      expect(route, '/library/collections/ward%20rounds%2F2026');
      expect(AppRoutes.isPublic(AppRoutes.collections), isFalse);
      expect(AppRoutes.isPublic(route), isFalse);
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
