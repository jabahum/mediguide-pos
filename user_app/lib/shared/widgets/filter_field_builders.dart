import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/core/utils/responsive.dart';

/// Static builder methods for different FormBuilder field types
class FilterFieldBuilders {
  FilterFieldBuilders._();

  /// Build a text input field
  static Widget buildTextField(FilterField field) {
    return FormBuilderTextField(
      name: field.name,
      enabled: field.enabled,
      initialValue: field.initialValue,
      decoration: InputDecoration(labelText: field.label, hintText: field.hint),
    );
  }

  /// Build a dropdown field
  static Widget buildDropdown(FilterField field) {
    return FormBuilderDropdown<String>(
      name: field.name,
      enabled: field.enabled,
      initialValue: field.initialValue,
      decoration: InputDecoration(labelText: field.label),
      items: field.options!
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
    );
  }

  /// Build a date range picker field
  static Widget buildDateRange(FilterField field) {
    return FormBuilderDateRangePicker(
      name: field.name,
      enabled: field.enabled,
      initialValue: field.initialValue,
      decoration: InputDecoration(
        labelText: field.label,
        suffixIcon: const Icon(Icons.date_range),
      ),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
  }

  /// Build a boolean checkbox field
  static Widget buildBoolean(FilterField field) {
    return FormBuilderField<bool>(
      name: field.name,
      initialValue: field.initialValue ?? false,
      enabled: field.enabled,
      builder: (FormFieldState<bool?> formField) {
        final context = formField.context;

        return CheckboxListTile(
          title: Text(
            field.label,
            style: context.textTheme.titleSmall?.copyWith(
              fontSize: Responsive.fontSize(context, mobile: 14, tablet: 16),
              fontWeight: FontWeight.w500,
            ),
          ),
          value: formField.value ?? false,
          onChanged: field.enabled
              ? (bool? value) => formField.didChange(value ?? false)
              : null,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          activeColor: context.theme.colorScheme.primary,
          checkColor: context.theme.colorScheme.onPrimary,
          controlAffinity: ListTileControlAffinity.leading,
        );
      },
    );
  }

  /// Build a number input field
  static Widget buildNumber(FilterField field) {
    return FormBuilderTextField(
      name: field.name,
      enabled: field.enabled,
      initialValue: field.initialValue?.toString(),
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        suffixIcon: const Icon(Icons.numbers),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  /// Build a multi-select choice chips field
  static Widget buildMultiSelect(FilterField field) {
    return FormBuilderField<List<String>>(
      name: field.name,
      initialValue: field.initialValue ?? <String>[],
      enabled: field.enabled,
      builder: (FormFieldState<List<String>?> formField) {
        final context = formField.context;
        final selectedValues = formField.value ?? <String>[];
        final fontSize = Responsive.fontSize(context, mobile: 14, tablet: 16);
        final chipSpacing = Responsive.doubleValue(
          context,
          mobile: 8.0,
          tablet: 10.0,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: context.textTheme.titleSmall?.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: chipSpacing,
              runSpacing: 6.0,
              children: field.options!.map((option) {
                final isSelected = selectedValues.contains(option);

                return FilterChip(
                  label: Text(
                    option,
                    semanticsLabel:
                        '${field.label}: $option ${isSelected ? "selected" : "not selected"}',
                  ),
                  selected: isSelected,
                  onSelected: field.enabled
                      ? (bool selected) {
                          final newValues = List<String>.from(selectedValues);
                          if (selected) {
                            newValues.add(option);
                          } else {
                            newValues.remove(option);
                          }
                          formField.didChange(newValues);
                        }
                      : null,
                  showCheckmark: true,
                  selectedColor: context.theme.colorScheme.primaryContainer,
                  checkmarkColor: context.theme.colorScheme.onPrimaryContainer,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  /// Build a field based on its type
  static Widget buildField(FilterField field) {
    return switch (field.type) {
      FilterInputType.text => buildTextField(field),
      FilterInputType.dropdown => buildDropdown(field),
      FilterInputType.dateRange => buildDateRange(field),
      FilterInputType.boolean => buildBoolean(field),
      FilterInputType.number => buildNumber(field),
      FilterInputType.multiSelect => buildMultiSelect(field),
    };
  }
}
