import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/notifications/domain/notification_action_resolver.dart';

void main() {
  const guidelineId = '11111111-1111-4111-8111-111111111111';

  group('NotificationActionResolver', () {
    test('derives resource routes instead of trusting a supplied route', () {
      final target = NotificationActionResolver.resolve(
        action: const {
          'type': 'guideline',
          'resource_id': guidelineId,
          'route': 'https://attacker.test/ignored',
          'parameters': {'section': 'diagnosis'},
        },
      );

      expect(
        target?.location,
        '/public/guidelines/$guidelineId?section=diagnosis',
      );
      expect(target?.externalUri, isNull);
    });

    test('rejects malformed, hostile, and unsupported internal actions', () {
      for (final route in [
        'javascript:alert(1)',
        'data:text/html,bad',
        '//attacker.test/path',
        '/login',
        '/tools?redirect=https://attacker.test',
        '/unknown-route',
      ]) {
        expect(
          NotificationActionResolver.resolve(
            action: {'type': 'internal_route', 'route': route},
          ),
          isNull,
          reason: route,
        );
      }
      final sanitized = NotificationActionResolver.resolve(
        action: const {
          'type': 'internal_route',
          'route': '/tools',
          'parameters': {'redirect': 'https://attacker.test'},
        },
      );
      expect(sanitized?.location, '/tools');
    });

    test('allows only explicitly approved HTTPS external hosts', () {
      final approved = NotificationActionResolver.resolve(
        action: const {
          'type': 'approved_external_url',
          'route': 'https://www.who.int/publications/example',
        },
      );
      final rejected = NotificationActionResolver.resolve(
        action: const {
          'type': 'approved_external_url',
          'route': 'https://attacker.test/who.int',
        },
      );

      expect(approved?.externalUri?.host, 'www.who.int');
      expect(rejected, isNull);
    });

    test(
      'parses flattened push action data and ignores a hostile legacy URL',
      () {
        final target = NotificationActionResolver.fromPushData(const {
          'action_type': 'facility',
          'resource_id': guidelineId,
          'route': 'https://attacker.test/ignored',
          'action_url': 'javascript:alert(1)',
        });

        expect(target?.location, '/health-facilities/$guidelineId');
      },
    );

    test('retains safe legacy guideline links during client migration', () {
      final target = NotificationActionResolver.resolve(
        legacyActionUrl: '/public/guidelines/$guidelineId',
      );

      expect(target?.location, '/public/guidelines/$guidelineId');
    });
  });
}
