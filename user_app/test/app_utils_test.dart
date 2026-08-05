import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/core/utils/date_utils.dart';

void main() {
  setUpAll(() {
    Intl.defaultLocale = 'en_US';
  });

  group('AppDateUtils', () {
    test('formats dates consistently', () {
      final date = DateTime(2026, 5, 21, 14, 30);

      expect(AppDateUtils.formatDate(date), '21 May 2026');
      expect(AppDateUtils.formatDateTime(date), '21 May 2026 • 14:30');
    });
  });

  group('Common.parseApiError', () {
    test('removes the Exception prefix', () {
      expect(
        Common.parseApiError(Exception('Request failed')),
        'Request failed',
      );
    });

    test('returns a safe fallback for an empty error', () {
      expect(Common.parseApiError(''), 'An error occurred. Please try again.');
    });
  });
}
