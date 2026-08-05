import 'dart:io';

/// Converts relative imports and exports under `lib/` to package imports.
///
/// Run before a large source-tree move so imports continue to identify the
/// same library independently of the importing file's new location.
void main(List<String> arguments) {
  final packageRoot = Directory(
    arguments.isEmpty ? Directory.current.path : arguments.single,
  ).absolute;
  final lib = Directory('${packageRoot.path}/lib');

  if (!lib.existsSync()) {
    stderr.writeln('Run this tool from the Flutter package root.');
    exitCode = 64;
    return;
  }

  final directive = RegExp(
    r'''\b(import|export)\s+(['"])([^'"]+)\2''',
    multiLine: true,
  );

  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    final original = entity.readAsStringSync();
    final updated = original.replaceAllMapped(directive, (match) {
      final target = match.group(3)!;
      if (target.startsWith('dart:') || target.startsWith('package:')) {
        return match.group(0)!;
      }

      final resolved = entity.uri.resolve(target).toFilePath();
      if (!resolved.startsWith('${lib.path}/')) return match.group(0)!;

      final relative = resolved.substring(lib.path.length + 1);
      return '${match.group(1)} ${match.group(2)}package:user_app/$relative${match.group(2)}';
    });

    if (updated != original) entity.writeAsStringSync(updated);
  }
}
