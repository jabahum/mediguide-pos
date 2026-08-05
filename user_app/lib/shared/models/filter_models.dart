import 'package:flutter/material.dart';

/// Enum defining the types of filter input fields
enum FilterInputType {
  text(label: 'Text'),
  dropdown(label: 'Dropdown'),
  dateRange(label: 'Date Range'),
  boolean(label: 'Boolean'),
  number(label: 'Number'),
  multiSelect(label: 'Multi-Select');

  const FilterInputType({required this.label});

  final String label;
}

/// Model class representing a single filter field configuration
class FilterField {
  final String name;
  final String label;
  final FilterInputType type;
  final dynamic initialValue;
  final List<String>? options;
  final bool enabled;
  final String? hint;
  final double? min;
  final double? max;
  final Map<String, dynamic>? extra;

  const FilterField({
    required this.name,
    required this.label,
    required this.type,
    this.initialValue,
    this.options,
    this.enabled = true,
    this.hint,
    this.min,
    this.max,
    this.extra,
  });

  /// Factory constructor for text field
  factory FilterField.text(
    String name,
    String label, {
    String? hint,
    String? initialValue,
    bool enabled = true,
  }) {
    return FilterField(
      name: name,
      label: label,
      type: FilterInputType.text,
      hint: hint,
      initialValue: initialValue,
      enabled: enabled,
    );
  }

  /// Factory constructor for dropdown field
  factory FilterField.dropdown(
    String name,
    String label,
    List<String> options, {
    String? initialValue,
    bool enabled = true,
  }) {
    return FilterField(
      name: name,
      label: label,
      type: FilterInputType.dropdown,
      options: options,
      initialValue: initialValue,
      enabled: enabled,
    );
  }

  /// Factory constructor for date range field
  factory FilterField.dateRange(
    String name,
    String label, {
    DateTimeRange? initialValue,
    bool enabled = true,
  }) {
    return FilterField(
      name: name,
      label: label,
      type: FilterInputType.dateRange,
      initialValue: initialValue,
      enabled: enabled,
    );
  }

  /// Factory constructor for boolean field
  factory FilterField.boolean(
    String name,
    String label, {
    bool? initialValue,
    bool enabled = true,
  }) {
    return FilterField(
      name: name,
      label: label,
      type: FilterInputType.boolean,
      initialValue: initialValue,
      enabled: enabled,
    );
  }

  /// Factory constructor for number field
  factory FilterField.number(
    String name,
    String label, {
    double? initialValue,
    double? min,
    double? max,
    String? hint,
    bool enabled = true,
  }) {
    return FilterField(
      name: name,
      label: label,
      type: FilterInputType.number,
      initialValue: initialValue,
      min: min,
      max: max,
      hint: hint,
      enabled: enabled,
    );
  }

  /// Factory constructor for multi-select field
  factory FilterField.multiSelect(
    String name,
    String label,
    List<String> options, {
    List<String>? initialValue,
    bool enabled = true,
  }) {
    return FilterField(
      name: name,
      label: label,
      type: FilterInputType.multiSelect,
      options: options,
      initialValue: initialValue,
      enabled: enabled,
    );
  }
}

/// Result class containing the filtered form values
class FilterResult {
  final Map<String, dynamic> values;
  final bool hasValues;

  const FilterResult({required this.values, required this.hasValues});

  /// Convert the result to JSON map
  Map<String, dynamic> toJson() => values;

  /// Check if the result is empty
  bool get isEmpty => !hasValues;

  /// Check if the result is not empty
  bool get isNotEmpty => hasValues;

  /// Get a specific value by key
  T? getValue<T>(String key) => values[key] as T?;

  /// Check if a specific key exists and has a value
  bool hasValue(String key) => values.containsKey(key) && values[key] != null;
}
