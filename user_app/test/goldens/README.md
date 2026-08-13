# Golden baselines

Flutter raster output differs between macOS and Linux even when the Flutter
and Dart versions match. The default files in this directory are the macOS
developer baselines. `linux/` contains the exact baselines used by the Ubuntu
GitHub Actions runner. Tests select the appropriate set through
`test/golden_test_support.dart`; pixel comparison remains exact on both hosts.

Use the project-pinned Flutter 3.44.8 SDK when reviewing or regenerating
goldens. Generate Linux files on an `linux/amd64` host that matches CI:

```bash
flutter test --update-goldens \
  test/full_screen_golden_matrix_test.dart \
  test/publication_block_golden_test.dart

flutter test \
  test/full_screen_golden_matrix_test.dart \
  test/publication_block_golden_test.dart
```

Never regenerate baselines merely to make a failure disappear. Inspect the
master, test, isolated-diff, and masked-diff artifacts first. CI uploads those
files as `mobile-golden-failures-<run-id>` when comparison fails.
