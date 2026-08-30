import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'production Android releases stay device-specific and size-governed',
    () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final workflow = File(
        '../.github/workflows/mobile-release.yml',
      ).readAsStringSync();

      expect(
        pubspec,
        isNot(contains('    - assets/\n')),
        reason: 'A broad asset declaration packages generator-only artwork.',
      );
      expect(workflow, contains('--split-per-abi'));
      expect(
        RegExp(
          r'--target-platform android-arm,android-arm64',
        ).allMatches(workflow).length,
        greaterThanOrEqualTo(2),
      );
      expect(workflow, contains('max_apk_bytes='));
      expect(workflow, contains('max_aab_bytes='));
    },
  );
}
