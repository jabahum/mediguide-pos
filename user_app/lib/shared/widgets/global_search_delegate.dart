import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/features/abbreviations/data/models/abbreviation.dart';
import 'package:user_app/features/calculators/data/models/calculator.dart';
import 'package:user_app/features/consultants/data/models/consultant.dart';
import 'package:user_app/features/drugs/data/models/drug.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/facilities/data/models/health_facility.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/shared/models/search_models.dart';
import 'package:user_app/features/search/presentation/controllers/global_search_controller.dart';
import 'package:user_app/features/drugs/presentation/widgets/drug_details_bottom_sheet.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/utils/loading.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:url_launcher/url_launcher.dart';

/// Global search delegate following Material Design and app theme
class GlobalSearchDelegate extends SearchDelegate<String?> {
  GlobalSearchDelegate({String? hintText})
    : super(
        searchFieldLabel: hintText ?? 'Search MediGuide...',
        searchFieldDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          hintStyle: TextStyle(fontSize: 16),
        ),
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      // Clear search button
      if (query.isNotEmpty)
        Consumer(
          builder: (context, ref, _) => IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () {
              query = '';
              ref.read(globalSearchControllerProvider.notifier).clear();
              showSuggestions(context);
            },
            tooltip: 'Clear search',
          ),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowLeft),
      onPressed: () => close(context, null),
      tooltip: 'Back',
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final search = ref.watch(globalSearchControllerProvider);
        if (query.trim() != search.query) {
          Future<void>.microtask(
            () =>
                ref.read(globalSearchControllerProvider.notifier).search(query),
          );
        }

        if (search.validationMessage.isNotEmpty) {
          return _buildMessageState(context, search.validationMessage);
        }

        if (search.isLoading && search.results.isEmpty) {
          return _buildLoadingState(context);
        }

        if (search.error != null) {
          return _buildMessageState(
            context,
            'Search failed. Please try again.',
          );
        }

        if (search.results.isEmpty && query.isNotEmpty) {
          return _buildEmptyState(context);
        }

        return _buildResultsList(context, ref, search);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Always show search prompt in suggestions (no auto-search)
    return _buildSearchPrompt(context);
  }

  Widget _buildMessageState(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsiveHorizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.search,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.md.gap,
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Loading.large(),
          AppSpacing.md.gap,
          Text(
            'Searching...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsiveHorizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.search,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.lg.gap,
            Text(
              'No Results Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            AppSpacing.sm.gap,
            Text(
              'Try adjusting your search or changing the category filter.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.lg.gap,
            OutlinedButton.icon(
              onPressed: () {
                query = '';
                showSuggestions(context);
              },
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build results list
  Widget _buildResultsList(
    BuildContext context,
    WidgetRef ref,
    GlobalSearchState search,
  ) {
    // Group results by category
    final grouped = <SearchCategory, List<SearchResult>>{};
    for (final result in search.results) {
      grouped.putIfAbsent(result.category, () => []).add(result);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveHorizontalPadding,
        vertical: AppSpacing.sm,
      ),
      itemCount: grouped.length,
      itemBuilder: (context, sectionIndex) {
        final category = grouped.keys.elementAt(sectionIndex);
        final items = grouped[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sectionIndex > 0) AppSpacing.gapMd,
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 14,
                    color: context.theme.colorScheme.primary,
                  ),
                  AppSpacing.hGapXs,
                  Text(
                    category.displayName.toUpperCase(),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Divider(
                      height: 1,
                      color: context.theme.colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Items
            ...items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return _buildSearchResultItem(
                context,
                entry.value,
                ref,
                showDivider: !isLast,
              );
            }),
          ],
        );
      },
    );
  }

  /// Build search result item
  Widget _buildSearchResultItem(
    BuildContext context,
    SearchResult result,
    WidgetRef ref, {
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: () async {
        close(context, result.title);
        await _selectSearchResult(ref, result);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (result.subtitle != null) ...[
                        AppSpacing.gapXs,
                        Text(
                          result.subtitle!,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (result.description != null) ...[
                        AppSpacing.gapXs,
                        Text(
                          result.description!,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.hGapSm,
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: context.theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            if (showDivider)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Divider(
                  height: 1,
                  color: context.theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectSearchResult(WidgetRef ref, SearchResult result) async {
    await ref
        .read(globalSearchControllerProvider.notifier)
        .recordSelection(result);
    switch (result.category) {
      case SearchCategory.drugs:
        final drug = result.getItem<Drug>();
        if (drug == null) {
          AppMessage.error(
            AppKeys.navigatorKey.currentContext!,
            'Drug not found',
          );
          return;
        }
        await ref
            .read(globalSearchControllerProvider.notifier)
            .recordDrugUsage(drug.id);
        final appContext = AppNavigator.context;
        if (!appContext.mounted) return;
        await DrugDetailsBottomSheet.show(context: appContext, drug: drug);
      case SearchCategory.guidelines:
        final guideline = result.getItem<GuidelinePublication>();
        if (guideline != null) {
          AppNavigator.push(
            AppRoutes.publicGuideline(guideline.id),
            extra: guideline,
          );
        }
      case SearchCategory.consultants:
        final consultant = result.getItem<Consultant>();
        if (consultant != null) {
          AppNavigator.push(
            AppRoutes.consultant(consultant.id),
            extra: consultant,
          );
        }
      case SearchCategory.healthFacilities:
        final facility = result.getItem<HealthFacility>();
        if (facility != null) {
          AppNavigator.push(
            AppRoutes.healthFacility(facility.id),
            extra: facility,
          );
        }
      case SearchCategory.abbreviations:
        final abbreviation = result.getItem<Abbreviation>();
        if (abbreviation != null) {
          AppNavigator.push(AppRoutes.abbreviations, extra: abbreviation);
        }
      case SearchCategory.tools:
        final calculator = result.getItem<Calculator>();
        AppNavigator.push(
          AppRoutes.calculator(calculator?.id ?? result.id),
          extra: calculator ?? {'calculatorId': result.id},
        );
      case SearchCategory.faq:
        if (result.item != null) {
          AppNavigator.push(AppRoutes.faq, extra: result.item);
        }
      case SearchCategory.outbreaks:
        final outbreak = result.getItem<PublicOutbreak>();
        AppNavigator.push(
          AppRoutes.outbreak(outbreak?.id ?? result.id),
          extra: outbreak,
        );
      case SearchCategory.outbreakDocuments:
        final document = result.getItem<PublicOutbreakDocument>();
        if (document != null) {
          AppNavigator.push(
            AppRoutes.outbreakDocument(document.outbreakId, document.id),
            extra: document,
          );
        }
      case SearchCategory.outbreakResources:
        if (result.route != null) {
          AppNavigator.push(result.route!, extra: result.item);
          return;
        }
        final external = Uri.tryParse(result.externalUrl ?? '');
        if (external == null) return;
        final appContext = AppNavigator.context;
        if (!appContext.mounted) return;
        final confirmed = await showDialog<bool>(
          context: appContext,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Open external official resource?'),
            content: Text('You are leaving MediGuide and opening:\n$external'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Open website'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          try {
            final launched = await launchUrl(
              external,
              mode: LaunchMode.externalApplication,
            );
            if (!launched && appContext.mounted) {
              AppMessage.error(
                appContext,
                'Unable to open this official resource.',
              );
            }
          } catch (_) {
            if (appContext.mounted) {
              AppMessage.error(
                appContext,
                'Unable to open this official resource.',
              );
            }
          }
        }
      case SearchCategory.situationReports:
        final report = result.getItem<PublicSituationReport>();
        AppNavigator.push(
          AppRoutes.situationReport(report?.id ?? result.id),
          extra: report,
        );
      case SearchCategory.all:
        if (result.route != null) {
          AppNavigator.push(result.route!, extra: result.routeArguments);
        }
    }
  }

  /// Build search prompt
  Widget _buildSearchPrompt(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsiveHorizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.search,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            AppSpacing.lg.gap,
            Text(
              'Search MediGuide',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            AppSpacing.sm.gap,
            Text(
              'Find drugs, consultants, health facilities, and more',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Get icon for search category
  IconData _getCategoryIcon(SearchCategory category) {
    switch (category) {
      case SearchCategory.all:
        return LucideIcons.search;
      case SearchCategory.drugs:
        return LucideIcons.pill;
      case SearchCategory.guidelines:
        return LucideIcons.fileText;
      case SearchCategory.consultants:
        return LucideIcons.user;
      case SearchCategory.healthFacilities:
        return LucideIcons.building2;
      case SearchCategory.abbreviations:
        return LucideIcons.type;
      case SearchCategory.faq:
        return LucideIcons.messageCircle;
      case SearchCategory.outbreaks:
        return LucideIcons.siren;
      case SearchCategory.outbreakDocuments:
        return LucideIcons.files;
      case SearchCategory.outbreakResources:
        return LucideIcons.externalLink;
      case SearchCategory.situationReports:
        return LucideIcons.fileChartColumn;
      case SearchCategory.tools:
        return LucideIcons.wrench;
    }
  }
}
