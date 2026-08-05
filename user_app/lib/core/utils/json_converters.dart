import 'package:json_annotation/json_annotation.dart';

class NullableDateTimeConverter implements JsonConverter<DateTime?, Object?> {
  const NullableDateTimeConverter();

  @override
  DateTime? fromJson(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    final text = value.toString().trim();
    return text.isEmpty ? null : DateTime.tryParse(text);
  }

  @override
  Object? toJson(DateTime? value) => value?.toUtc().toIso8601String();
}
