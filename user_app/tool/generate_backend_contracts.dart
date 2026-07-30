import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  final input = File(
    arguments.isNotEmpty ? arguments[0] : '../backend/docs/swagger.json',
  );
  final output = File(
    arguments.length > 1
        ? arguments[1]
        : 'lib/app/data/contracts/generated/backend_contracts.dart',
  );

  if (!input.existsSync()) {
    stderr.writeln('Missing backend Swagger document: ${input.path}');
    exitCode = 1;
    return;
  }

  final document = jsonDecode(input.readAsStringSync());
  if (document is! Map<String, dynamic>) {
    stderr.writeln('Backend Swagger document must be a JSON object');
    exitCode = 1;
    return;
  }

  final definitions = _map(document['definitions']);
  final names = definitions.keys.toList()..sort();
  final buffer = StringBuffer()
    ..writeln('// GENERATED FILE — DO NOT EDIT.')
    ..writeln('// Source: backend/docs/swagger.json')
    ..writeln('// Generator: tool/generate_backend_contracts.dart')
    ..writeln()
    ..writeln("import 'dart:collection';")
    ..writeln()
    ..writeln('Map<String, dynamic> _jsonMap(Object? value) {')
    ..writeln('  if (value is Map<String, dynamic>) return value;')
    ..writeln('  if (value is Map) return Map<String, dynamic>.from(value);')
    ..writeln('  return const <String, dynamic>{};')
    ..writeln('}')
    ..writeln();

  for (final definitionName in names) {
    final schema = _map(definitions[definitionName]);
    _writeContract(buffer, definitionName, schema);
  }

  output.parent.createSync(recursive: true);
  output.writeAsStringSync(buffer.toString());
  stdout.writeln('Generated mobile contracts: ${output.path}');
}

void _writeContract(
  StringBuffer buffer,
  String definitionName,
  Map<String, dynamic> schema,
) {
  final className = _className(definitionName);
  final properties = _map(schema['properties']);
  final propertyNames = properties.keys.toList()..sort();

  buffer
    ..writeln('final class $className {')
    ..writeln('  $className(Map<String, dynamic> value)')
    ..writeln(
      '      : value = UnmodifiableMapView<String, dynamic>(Map.of(value));',
    )
    ..writeln()
    ..writeln(
      '  factory $className.fromJson(Map<String, dynamic> json) => $className(json);',
    )
    ..writeln()
    ..writeln("  static const schemaName = '$definitionName';")
    ..writeln('  final Map<String, dynamic> value;')
    ..writeln();

  for (final propertyName in propertyNames) {
    final property = _map(properties[propertyName]);
    _writeGetter(buffer, propertyName, property);
  }

  buffer
    ..writeln('  Map<String, dynamic> toJson() => Map.of(value);')
    ..writeln('}')
    ..writeln();
}

void _writeGetter(
  StringBuffer buffer,
  String jsonName,
  Map<String, dynamic> schema,
) {
  final fieldName = _fieldName(jsonName);
  final reference = schema[r'$ref']?.toString();
  if (reference != null && reference.isNotEmpty) {
    final target = _className(reference.split('/').last);
    buffer
      ..writeln('  $target? get $fieldName {')
      ..writeln("    final raw = value['$jsonName'];")
      ..writeln('    if (raw is! Map) return null;')
      ..writeln('    return $target.fromJson(_jsonMap(raw));')
      ..writeln('  }')
      ..writeln();
    return;
  }

  final type = schema['type']?.toString();
  if (type == 'array') {
    final items = _map(schema['items']);
    final itemReference = items[r'$ref']?.toString();
    final itemType = items['type']?.toString();
    if (itemReference != null && itemReference.isNotEmpty) {
      final target = _className(itemReference.split('/').last);
      buffer
        ..writeln('  List<$target> get $fieldName {')
        ..writeln("    final raw = value['$jsonName'];")
        ..writeln('    if (raw is! List) return const [];')
        ..writeln(
          '    return raw.whereType<Map>().map((item) => $target.fromJson(_jsonMap(item))).toList(growable: false);',
        )
        ..writeln('  }')
        ..writeln();
      return;
    }
    final dartItemType = _primitiveType(itemType);
    buffer
      ..writeln('  List<$dartItemType> get $fieldName {')
      ..writeln("    final raw = value['$jsonName'];")
      ..writeln('    if (raw is! List) return const [];')
      ..writeln(
        '    return raw.whereType<$dartItemType>().toList(growable: false);',
      )
      ..writeln('  }')
      ..writeln();
    return;
  }

  switch (type) {
    case 'string':
      buffer.writeln(
        "  String? get $fieldName => value['$jsonName']?.toString();",
      );
    case 'integer':
      buffer.writeln(
        "  int? get $fieldName => (value['$jsonName'] as num?)?.toInt();",
      );
    case 'number':
      buffer.writeln("  num? get $fieldName => value['$jsonName'] as num?;");
    case 'boolean':
      buffer.writeln("  bool? get $fieldName => value['$jsonName'] as bool?;");
    case 'object':
      buffer.writeln(
        "  Map<String, dynamic> get $fieldName => _jsonMap(value['$jsonName']);",
      );
    default:
      buffer.writeln("  Object? get $fieldName => value['$jsonName'];");
  }
  buffer.writeln();
}

String _primitiveType(String? type) {
  return switch (type) {
    'string' => 'String',
    'integer' => 'int',
    'number' => 'num',
    'boolean' => 'bool',
    'object' => 'Map<String, dynamic>',
    _ => 'Object?',
  };
}

String _className(String value) {
  final parts = value
      .split(RegExp('[^A-Za-z0-9]+'))
      .where((part) => part.isNotEmpty);
  final result = parts.map(_capitalize).join();
  return result.isEmpty ? 'BackendContract' : result;
}

String _fieldName(String value) {
  final parts = value
      .split(RegExp('[^A-Za-z0-9]+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'field';
  final candidate =
      parts.first.toLowerCase() + parts.skip(1).map(_capitalize).join();
  return _dartKeywords.contains(candidate) ? '${candidate}Value' : candidate;
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

const _dartKeywords = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};
