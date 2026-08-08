import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/responsive.dart';

import 'package:user_app/features/ai_assistant/data/services/ai_context_service.dart';
import 'package:user_app/features/ai_assistant/data/models/ai_context.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/route_names.dart';

/// Bottom sheet for displaying comprehensive drug details
class DrugDetailsBottomSheet extends ConsumerWidget {
  final Drug drug;

  const DrugDetailsBottomSheet({super.key, required this.drug});

  /// Show the drug details bottom sheet
  static Future<void> show({
    required BuildContext context,
    required Drug drug,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => DrugDetailsBottomSheet(drug: drug),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextService = ref.watch(aiContextServiceProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveHorizontalPadding,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header — name + AI button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      drug.name,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: context.theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _showAiAssistant(contextService),
                      icon: Icon(
                        LucideIcons.sparkles,
                        color: context.theme.colorScheme.primary,
                      ),
                      tooltip: 'Ask AI about this medication',
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),

              // Brand names
              if (drug.brandNames.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '${'brand'.tr}: ${drug.brandNames}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: context.theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              AppSpacing.gapSm,

              // Status tags
              Text(
                [
                  if (drug.categories.isNotEmpty)
                    ...drug.categories.take(3).map((c) => c.name),
                  if (drug.whoEmlStatus) 'WHO EML',
                  if (drug.antimicrobialStatus) 'antimicrobial'.tr,
                  if (drug.pregnancyCategory != null)
                    '${'pregnancyCat'.tr} ${drug.pregnancyCategory!.label}',
                  if (drug.controlledSubstance != null &&
                      drug.controlledSubstance!.label != 'None')
                    drug.controlledSubstance!.label,
                ].join(' · '),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              AppSpacing.gapLg,

              // Description
              if (drug.description.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'description'.tr,
                  LucideIcons.fileText,
                ),
                AppSpacing.gapSm,
                _buildHtmlContent(context, drug.description),
                AppSpacing.gapLg,
              ],

              // Mechanism of Action
              if (drug.mechanismOfAction.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'mechanismOfAction'.tr,
                  LucideIcons.activity,
                ),
                AppSpacing.gapSm,
                _buildHtmlContent(context, drug.mechanismOfAction),
                AppSpacing.gapLg,
              ],

              // Dosing Information
              if (_hasDosageInfo()) ...[
                _buildSectionHeader(context, 'dosing'.tr, LucideIcons.droplets),
                AppSpacing.gapSm,

                if (drug.adultDose.isNotEmpty)
                  _buildInfoRow(
                    context,
                    'adultDose'.tr,
                    drug.adultDose,
                    LucideIcons.user,
                  ),

                if (drug.pediatricDose.isNotEmpty)
                  _buildInfoRow(
                    context,
                    'pediatricDose'.tr,
                    drug.pediatricDose,
                    LucideIcons.baby,
                  ),

                if (drug.elderlyDose.isNotEmpty)
                  _buildInfoRow(
                    context,
                    'elderlyDose'.tr,
                    drug.elderlyDose,
                    LucideIcons.userCheck,
                  ),

                if (drug.maxDailyDose.isNotEmpty)
                  _buildInfoRow(
                    context,
                    'maxDailyDose'.tr,
                    drug.maxDailyDose,
                    LucideIcons.triangleAlert,
                  ),

                if (drug.frequency.isNotEmpty)
                  _buildInfoRow(
                    context,
                    'frequency'.tr,
                    drug.frequency,
                    LucideIcons.clock,
                  ),

                if (drug.duration.isNotEmpty)
                  _buildInfoRow(
                    context,
                    'duration'.tr,
                    drug.duration,
                    LucideIcons.calendar,
                  ),

                AppSpacing.gapLg,
              ],

              // Administration
              if (_hasAdministrationInfo()) ...[
                _buildSectionHeader(
                  context,
                  'administration'.tr,
                  LucideIcons.pill,
                ),
                AppSpacing.gapSm,

                if (drug.routeOfAdministration.isNotEmpty)
                  _buildInfoRow(
                    context,
                    'route'.tr,
                    drug.routeOfAdministration
                        .map((r) => r.displayName)
                        .join(', '),
                    LucideIcons.route,
                  ),

                if (drug.monitoringParameters.isNotEmpty)
                  _buildInfoRow(
                    context,
                    'monitoring'.tr,
                    drug.monitoringParameters,
                    LucideIcons.stethoscope,
                  ),

                AppSpacing.gapLg,
              ],

              // Clinical Information
              if (drug.indications.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'indications'.tr,
                  LucideIcons.target,
                ),
                AppSpacing.gapSm,
                _buildHtmlContent(context, drug.indications),
                AppSpacing.gapLg,
              ],

              if (drug.contraindications.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'contraindications'.tr,
                  LucideIcons.x,
                ),
                AppSpacing.gapSm,
                _buildHtmlContent(context, drug.contraindications),
                AppSpacing.gapLg,
              ],

              if (drug.sideEffects.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'sideEffects'.tr,
                  LucideIcons.triangleAlert,
                ),
                AppSpacing.gapSm,
                _buildHtmlContent(context, drug.sideEffects),
                AppSpacing.gapLg,
              ],

              if (drug.warnings.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'warnings'.tr,
                  LucideIcons.triangleAlert,
                ),
                AppSpacing.gapSm,
                _buildHtmlContent(context, drug.warnings),
                AppSpacing.gapLg,
              ],

              // Clinical Notes
              if (drug.clinicalNotes.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'clinicalNotes'.tr,
                  LucideIcons.notepadText,
                ),
                AppSpacing.gapSm,
                _buildHtmlContent(context, drug.clinicalNotes),
                AppSpacing.gapLg,
              ],

              // References
              if (drug.references.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'references'.tr,
                  LucideIcons.bookOpen,
                ),
                AppSpacing.gapSm,
                _buildHtmlContent(context, drug.references),
                AppSpacing.gapLg,
              ],

              // Additional Information
              if (_hasAdditionalInfo()) ...[
                _buildSectionHeader(
                  context,
                  'additionalInfo'.tr,
                  LucideIcons.info,
                ),
                AppSpacing.gapSm,

                if (drug.tags.isNotEmpty) ...[
                  _buildInfoRow(
                    context,
                    'tags'.tr,
                    drug.tags.map((t) => t.name).join(', '),
                    LucideIcons.tag,
                  ),
                ],

                if (drug.drugClass != null) ...[
                  _buildInfoRow(
                    context,
                    'drugClass'.tr,
                    drug.drugClass!.name,
                    LucideIcons.layers,
                  ),
                ],

                if (drug.therapeuticCategory != null) ...[
                  _buildInfoRow(
                    context,
                    'therapeuticCategory'.tr,
                    drug.therapeuticCategory!.name,
                    LucideIcons.activity,
                  ),
                ],

                if (drug.searchKeywords.isNotEmpty) ...[
                  _buildInfoRow(
                    context,
                    'keywords'.tr,
                    drug.searchKeywords,
                    LucideIcons.search,
                  ),
                ],

                AppSpacing.gapLg,
              ],

              // Bottom padding for safe area
              SizedBox(height: context.responsiveVerticalPadding),
            ],
          ),
        );
      },
    );
  }

  /// Build section header — uppercase label with divider
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final cs = context.theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// Build HTML content with proper styling
  Widget _buildHtmlContent(BuildContext context, String htmlContent) {
    return Html(
      data: htmlContent,
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(context.textTheme.bodyMedium?.fontSize ?? 14),
          color: context.theme.colorScheme.onSurface,
          lineHeight: const LineHeight(1.5),
        ),
        'p': Style(margin: Margins.only(bottom: AppSpacing.sm)),
        'ul': Style(
          margin: Margins.only(left: AppSpacing.md, bottom: AppSpacing.sm),
        ),
        'ol': Style(
          margin: Margins.only(left: AppSpacing.md, bottom: AppSpacing.sm),
        ),
        'li': Style(margin: Margins.only(bottom: AppSpacing.xs)),
      },
    );
  }

  /// Build info row with icon, label, and value
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.theme.colorScheme.outline),
          AppSpacing.hGapSm,
          Expanded(
            child: RichText(
              text: TextSpan(
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.theme.colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if drug has dosage information
  bool _hasDosageInfo() {
    return drug.adultDose.isNotEmpty ||
        drug.pediatricDose.isNotEmpty ||
        drug.elderlyDose.isNotEmpty ||
        drug.maxDailyDose.isNotEmpty ||
        drug.frequency.isNotEmpty ||
        drug.duration.isNotEmpty;
  }

  /// Check if drug has administration information
  bool _hasAdministrationInfo() {
    return drug.routeOfAdministration.isNotEmpty ||
        drug.monitoringParameters.isNotEmpty;
  }

  /// Check if drug has additional information
  bool _hasAdditionalInfo() {
    return drug.tags.isNotEmpty ||
        drug.drugClass != null ||
        drug.therapeuticCategory != null ||
        drug.searchKeywords.isNotEmpty;
  }

  /// Navigate to AI assistant with drug context
  void _showAiAssistant(AiContextService contextService) {
    final drugContext = _buildDrugContext(contextService);
    AppNavigator.push(
      AppRoutes.aiAssistant,
      extra: {'aiContext': drugContext.toJson()},
    );
  }

  /// Build AI context from drug data
  AiContext _buildDrugContext(AiContextService contextService) {
    // Build comprehensive drug content for AI
    final contentBuffer = StringBuffer();

    // Basic information
    contentBuffer.writeln('Drug Name: ${drug.name}');
    if (drug.brandNames.isNotEmpty) {
      contentBuffer.writeln('Brand Names: ${drug.brandNames}');
    }

    // Categories and classifications
    if (drug.categories.isNotEmpty) {
      contentBuffer.writeln(
        'Categories: ${drug.categories.map((c) => c.name).join(', ')}',
      );
    }
    if (drug.drugClass != null) {
      contentBuffer.writeln('Drug Class: ${drug.drugClass!.name}');
    }
    if (drug.therapeuticCategory != null) {
      contentBuffer.writeln(
        'Therapeutic Category: ${drug.therapeuticCategory!.name}',
      );
    }

    // Clinical information
    if (drug.description.isNotEmpty) {
      contentBuffer.writeln('\nDescription:');
      contentBuffer.writeln(contextService.cleanHtmlContent(drug.description));
    }

    if (drug.mechanismOfAction.isNotEmpty) {
      contentBuffer.writeln('\nMechanism of Action:');
      contentBuffer.writeln(
        contextService.cleanHtmlContent(drug.mechanismOfAction),
      );
    }

    if (drug.indications.isNotEmpty) {
      contentBuffer.writeln('\nIndications:');
      contentBuffer.writeln(contextService.cleanHtmlContent(drug.indications));
    }

    // Dosing information
    if (_hasDosageInfo()) {
      contentBuffer.writeln('\nDosing Information:');
      if (drug.adultDose.isNotEmpty) {
        contentBuffer.writeln('Adult Dose: ${drug.adultDose}');
      }
      if (drug.pediatricDose.isNotEmpty) {
        contentBuffer.writeln('Pediatric Dose: ${drug.pediatricDose}');
      }
      if (drug.elderlyDose.isNotEmpty) {
        contentBuffer.writeln('Elderly Dose: ${drug.elderlyDose}');
      }
      if (drug.maxDailyDose.isNotEmpty) {
        contentBuffer.writeln('Maximum Daily Dose: ${drug.maxDailyDose}');
      }
      if (drug.frequency.isNotEmpty) {
        contentBuffer.writeln('Frequency: ${drug.frequency}');
      }
      if (drug.duration.isNotEmpty) {
        contentBuffer.writeln('Duration: ${drug.duration}');
      }
    }

    // Administration
    if (drug.routeOfAdministration.isNotEmpty) {
      contentBuffer.writeln(
        '\nRoute of Administration: ${drug.routeOfAdministration.map((r) => r.displayName).join(', ')}',
      );
    }
    if (drug.monitoringParameters.isNotEmpty) {
      contentBuffer.writeln(
        'Monitoring Parameters: ${drug.monitoringParameters}',
      );
    }

    // Safety information
    if (drug.contraindications.isNotEmpty) {
      contentBuffer.writeln('\nContraindications:');
      contentBuffer.writeln(
        contextService.cleanHtmlContent(drug.contraindications),
      );
    }

    if (drug.sideEffects.isNotEmpty) {
      contentBuffer.writeln('\nSide Effects:');
      contentBuffer.writeln(contextService.cleanHtmlContent(drug.sideEffects));
    }

    if (drug.warnings.isNotEmpty) {
      contentBuffer.writeln('\nWarnings:');
      contentBuffer.writeln(contextService.cleanHtmlContent(drug.warnings));
    }

    // Special considerations
    if (drug.pregnancyCategory != null) {
      contentBuffer.writeln(
        '\nPregnancy Category: ${drug.pregnancyCategory!.label}',
      );
    }
    if (drug.controlledSubstance != null &&
        drug.controlledSubstance!.label != 'None') {
      contentBuffer.writeln(
        'Controlled Substance: ${drug.controlledSubstance!.label}',
      );
    }
    if (drug.antimicrobialStatus) {
      contentBuffer.writeln('Antimicrobial Status: Yes');
    }
    if (drug.whoEmlStatus) {
      contentBuffer.writeln('WHO Essential Medicines List: Yes');
    }

    // Clinical notes and references
    if (drug.clinicalNotes.isNotEmpty) {
      contentBuffer.writeln('\nClinical Notes:');
      contentBuffer.writeln(
        contextService.cleanHtmlContent(drug.clinicalNotes),
      );
    }

    if (drug.references.isNotEmpty) {
      contentBuffer.writeln('\nReferences:');
      contentBuffer.writeln(contextService.cleanHtmlContent(drug.references));
    }

    return AiContext.drug(
      drugName: drug.name,
      content: contentBuffer.toString(),
      drugId: drug.id,
      metadata: {
        'brandNames': drug.brandNames,
        'categories': drug.categories.map((c) => c.name).toList(),
        'drugClass': drug.drugClass?.name,
        'therapeuticCategory': drug.therapeuticCategory?.name,
        'whoEmlStatus': drug.whoEmlStatus,
        'antimicrobialStatus': drug.antimicrobialStatus,
        'pregnancyCategory': drug.pregnancyCategory?.label,
        'controlledSubstance': drug.controlledSubstance?.label,
        'hasDosageInfo': _hasDosageInfo(),
        'hasAdministrationInfo': _hasAdministrationInfo(),
      },
    );
  }
}
