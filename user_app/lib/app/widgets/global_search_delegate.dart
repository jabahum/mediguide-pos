import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/models/abbreviation.dart';
import '../data/models/calculator.dart';
import '../data/models/consultant.dart';
import '../data/models/drug.dart';
import '../data/models/guideline.dart';
import '../data/models/health_facility.dart';
import '../data/models/search_models.dart';
import '../features/search/global_search_controller.dart';
import '../modules/drug_index_module/widgets/drug_details_bottom_sheet.dart';
import '../routes/app_pages.dart';
import '../utils/common.dart';
import '../utils/loading.dart';
import '../utils/responsive.dart';
import '../utils/app_spacing.dart';

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
    switch (result.category) {
      case SearchCategory.drugs:
        final drug = result.getItem<Drug>();
        if (drug == null) {
          Common.quickToast(title: 'drugNotFound'.tr);
          return;
        }
        await ref
            .read(globalSearchControllerProvider.notifier)
            .recordDrugUsage(drug.id);
        final appContext = Get.context;
        if (appContext == null || !appContext.mounted) return;
        await DrugDetailsBottomSheet.show(context: appContext, drug: drug);
      case SearchCategory.guidelines:
        final guideline = result.getItem<Guideline>();
        if (guideline != null) {
          Get.toNamed(AppRoutes.readGuideline, arguments: guideline);
        }
      case SearchCategory.consultants:
        final consultant = result.getItem<Consultant>();
        if (consultant != null) {
          Get.toNamed(AppRoutes.consultants, arguments: consultant);
        }
      case SearchCategory.healthFacilities:
        final facility = result.getItem<HealthFacility>();
        if (facility != null) {
          Get.toNamed(AppRoutes.healthInfrastructure, arguments: facility);
        }
      case SearchCategory.abbreviations:
        final abbreviation = result.getItem<Abbreviation>();
        if (abbreviation != null) {
          Get.toNamed(AppRoutes.abbreviations, arguments: abbreviation);
        }
      case SearchCategory.tools:
        final calculator = result.getItem<Calculator>();
        Get.toNamed(
          AppRoutes.useCalculator,
          arguments: calculator ?? {'calculatorId': result.id},
        );
      case SearchCategory.faq:
        if (result.item != null) {
          Get.toNamed(AppRoutes.faq, arguments: result.item);
        }
      case SearchCategory.all:
        if (result.route != null) {
          Get.toNamed(result.route!, arguments: result.routeArguments);
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
      case SearchCategory.tools:
        return LucideIcons.wrench;
    }
  }
}
