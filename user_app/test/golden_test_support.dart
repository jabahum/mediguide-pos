import 'dart:io';

/// Resolves exact golden baselines for the renderer used by the test host.
///
/// Flutter's macOS and Linux engines can rasterize the same scene differently.
/// Keep separate Linux masters for GitHub Actions instead of weakening the
/// pixel comparator and allowing small, real regressions through unnoticed.
String platformGolden(String relativePath) {
  if (Platform.isLinux) {
    return 'goldens/linux/$relativePath';
  }
  return 'goldens/$relativePath';
}
