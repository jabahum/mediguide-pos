import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/models/filter_models.dart';
import '../utils/app_spacing.dart';
import '../utils/responsive.dart';
import 'app_button.dart';
import 'filter_field_builders.dart';

/// Generic filter bottom sheet using standard Flutter bottom sheet
class GenericFilterBottomSheet {
  /// Show the filter bottom sheet
  static Future<FilterResult?> show({
    required BuildContext context,
    required String title,
    required List<FilterField> fields,
    Map<String, dynamic>? initialValues,
  }) {
    return showModalBottomSheet<FilterResult>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        snap: true,
        snapSizes: const [0.3, 0.5, 0.9],
        builder: (context, scrollController) => Column(
          children: [
            // Header with title and close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'close'.tr,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _GenericFilterBottomSheetContent(
                fields: fields,
                initialValues: initialValues,
                scrollController: scrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal content widget for the filter bottom sheet
class _GenericFilterBottomSheetContent extends StatefulWidget {
  const _GenericFilterBottomSheetContent({
    required this.fields,
    this.initialValues,
    required this.scrollController,
  });

  final List<FilterField> fields;
  final Map<String, dynamic>? initialValues;
  final ScrollController scrollController;

  @override
  State<_GenericFilterBottomSheetContent> createState() =>
      _GenericFilterBottomSheetContentState();
}

class _GenericFilterBottomSheetContentState
    extends State<_GenericFilterBottomSheetContent> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveHorizontalPadding,
        vertical: AppSpacing.md,
      ),
      child: FormBuilder(
        key: _formKey,
        initialValue: widget.initialValues ?? {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dynamic field generation
            ...widget.fields.map(
              (field) => Padding(
                padding: AppSpacing.vPaddingSm,
                child: FilterFieldBuilders.buildField(field),
              ),
            ),

            AppSpacing.gapLg,

            // Action buttons card
            Row(
              children: [
                Expanded(
                  child: AppButtonVariants.outlined(
                    text: 'reset'.tr,
                    icon: LucideIcons.rotateCcw,
                    onPressed: () => _formKey.currentState?.reset(),
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: AppButton(
                    text: 'applyFilters'.tr,
                    icon: LucideIcons.check,
                    onPressed: () {
                      final values =
                          _formKey.currentState?.instantValue ??
                          <String, dynamic>{};

                      // Clean values: remove null, empty strings, empty lists
                      final cleanValues = <String, dynamic>{};

                      for (final entry in values.entries) {
                        final value = entry.value;
                        if (value != null) {
                          if (value is String && value.isNotEmpty) {
                            cleanValues[entry.key] = value;
                          } else if (value is List && value.isNotEmpty) {
                            cleanValues[entry.key] = value;
                          } else if (value is bool) {
                            // Include boolean values only if true
                            if (value) {
                              cleanValues[entry.key] = value;
                            }
                          } else if (value is DateTimeRange) {
                            cleanValues[entry.key] = {
                              'start': value.start.toIso8601String(),
                              'end': value.end.toIso8601String(),
                            };
                          } else if (value is! String && value is! List) {
                            // Include other non-null values (numbers, dates, etc.)
                            cleanValues[entry.key] = value;
                          }
                        }
                      }

                      final result = FilterResult(
                        values: cleanValues,
                        hasValues: cleanValues.isNotEmpty,
                      );

                      Navigator.of(context).pop(result);
                    },
                  ),
                ),
              ],
            ),

            // Bottom spacing for safe area
            SizedBox(height: context.responsiveVerticalPadding),
          ],
        ),
      ),
    );
  }
}
