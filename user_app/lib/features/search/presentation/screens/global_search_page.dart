import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/features/search/presentation/controllers/global_search_controller.dart';
import 'package:user_app/shared/models/search_models.dart';
import 'package:user_app/shared/widgets/clinical_icon_tile.dart';

class GlobalSearchPage extends ConsumerStatefulWidget {
  const GlobalSearchPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends ConsumerState<GlobalSearchPage> {
  final TextEditingController _controller = TextEditingController();

  SearchCategory _category = SearchCategory.all;

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();

    //
    // We still update immediately so the clear button responds
    // while the actual network/repository search remains debounced.
    //
    setState(() {});

    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;

      ref.read(globalSearchControllerProvider.notifier).search(value);
    });
  }

  void _submitSearch(String value) {
    _debounce?.cancel();

    ref.read(globalSearchControllerProvider.notifier).search(value);
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();

    ref.read(globalSearchControllerProvider.notifier).clear();

    setState(() {
      _category = SearchCategory.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(globalSearchControllerProvider);

    final categoryCounts = _categoryCounts(state.results);

    final visibleResults = _category == SearchCategory.all
        ? state.results
        : state.results
              .where((result) => result.category == _category)
              .toList(growable: false);

    final body = SafeArea(
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          //
          // Header + search
          //
          SliverPadding(
            padding: AppSpacing.pagePadding.copyWith(bottom: 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SearchHeader(
                    resultCount: state.hasQuery ? state.results.length : null,
                  ),

                  AppSpacing.gapMd,

                  _ClinicalSearchField(
                    controller: _controller,
                    onChanged: _search,
                    onSubmitted: _submitSearch,
                    onClear: _clearSearch,
                  ),

                  AppSpacing.gapMd,

                  _SearchCategoryFilters(
                    selected: _category,
                    counts: categoryCounts,
                    onSelected: (category) {
                      setState(() {
                        _category = category;
                      });
                    },
                  ),

                  AppSpacing.gapMd,

                  if (state.isLoading && state.hasQuery)
                    const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),

                  if (state.isLoading && state.hasQuery) AppSpacing.gapMd,
                ],
              ),
            ),
          ),

          //
          // Initial loading.
          //
          if (state.isLoading && !state.hasQuery)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _SearchMessage(
                icon: LucideIcons.search,
                title: 'Preparing search',
                message: 'Getting clinical search ready…',
                loading: true,
              ),
            )
          //
          // Error
          //
          else if (state.hasError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _SearchMessage(
                icon: LucideIcons.triangleAlert,
                title: 'Search unavailable',
                message:
                    'We could not complete your search. Check your connection and try again.',
                action: FilledButton.icon(
                  onPressed: () {
                    ref
                        .read(globalSearchControllerProvider.notifier)
                        .search(_controller.text);
                  },
                  icon: const Icon(LucideIcons.refreshCw),
                  label: const Text('Retry search'),
                ),
              ),
            )
          //
          // No search yet.
          //
          else if (!state.hasQuery)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _SearchMessage(
                icon: LucideIcons.search,
                title: 'Find clinical guidance',
                message:
                    'Search outbreaks, guidelines, medicines, clinical tools, facilities and other MediGuide resources.',
              ),
            )
          //
          // Validation / no results
          //
          else if (state.validationMessage.isNotEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _SearchMessage(
                icon: LucideIcons.textCursorInput,
                title: 'Keep typing',
                message: state.validationMessage,
              ),
            )
          else if (visibleResults.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _SearchMessage(
                icon: LucideIcons.fileSearch,
                title: _category == SearchCategory.all
                    ? 'No results found'
                    : 'No ${_category.displayName.toLowerCase()} found',
                message: _category == SearchCategory.all
                    ? 'Try another clinical term, medicine, abbreviation or service.'
                    : 'Try another category or broaden your search.',
                action: _category == SearchCategory.all
                    ? null
                    : OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _category = SearchCategory.all;
                          });
                        },
                        icon: const Icon(LucideIcons.listFilter),
                        label: const Text('Show all results'),
                      ),
              ),
            )
          //
          // Results
          //
          else
            SliverPadding(
              padding: AppSpacing.pagePadding.copyWith(top: 0),
              sliver: SliverToBoxAdapter(
                child: _GroupedSearchResults(
                  results: visibleResults,
                  query: state.query,
                  selectedCategory: _category,
                ),
              ),
            ),
        ],
      ),
    );

    return widget.embedded ? body : Scaffold(body: body);
  }

  Map<SearchCategory, int> _categoryCounts(List<SearchResult> results) {
    final counts = <SearchCategory, int>{SearchCategory.all: results.length};

    for (final result in results) {
      counts.update(result.category, (value) => value + 1, ifAbsent: () => 1);
    }

    return counts;
  }
}

/// ===========================================================================
/// HEADER
/// ===========================================================================

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({this.resultCount});

  final int? resultCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search', style: Theme.of(context).textTheme.headlineMedium),

              const SizedBox(height: 3),

              Text(
                'Search across MediGuide clinical resources',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),

        if (resultCount != null) _ResultCountBadge(count: resultCount!),
      ],
    );
  }
}

class _ResultCountBadge extends StatelessWidget {
  const _ResultCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count ${count == 1 ? 'result' : 'results'}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// ===========================================================================
/// SEARCH FIELD
/// ===========================================================================

class _ClinicalSearchField extends StatelessWidget {
  const _ClinicalSearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SearchBar(
      controller: controller,
      hintText: 'Search outbreaks, guidelines, drugs, tools…',
      leading: Icon(LucideIcons.search, color: colors.primary),
      trailing: [
        if (controller.text.isNotEmpty)
          IconButton(
            tooltip: 'Clear search',
            onPressed: onClear,
            icon: const Icon(LucideIcons.x),
          ),
      ],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(colors.surfaceContainerLow),
      side: WidgetStatePropertyAll(BorderSide(color: colors.outlineVariant)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }
}

/// ===========================================================================
/// FILTERS
/// ===========================================================================

class _SearchCategoryFilters extends StatelessWidget {
  const _SearchCategoryFilters({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final SearchCategory selected;

  final Map<SearchCategory, int> counts;

  final ValueChanged<SearchCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (
            var index = 0;
            index < SearchCategory.values.length;
            index++
          ) ...[
            _SearchFilterChip(
              category: SearchCategory.values[index],
              selected: selected == SearchCategory.values[index],
              count: counts[SearchCategory.values[index]] ?? 0,
              onTap: () {
                onSelected(SearchCategory.values[index]);
              },
            ),

            if (index != SearchCategory.values.length - 1)
              const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SearchFilterChip extends StatelessWidget {
  const _SearchFilterChip({
    required this.category,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  final SearchCategory category;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) {
        onTap();
      },
      avatar: Icon(_SearchResultTile.iconFor(category), size: 16),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.displayName),

          if (count > 0) ...[
            const SizedBox(width: 5),

            Container(
              constraints: const BoxConstraints(minWidth: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ===========================================================================
/// RESULTS
/// ===========================================================================

class _GroupedSearchResults extends StatelessWidget {
  const _GroupedSearchResults({
    required this.results,
    required this.query,
    required this.selectedCategory,
  });

  final List<SearchResult> results;
  final String query;
  final SearchCategory selectedCategory;

  @override
  Widget build(BuildContext context) {
    final groups = <SearchCategory, List<SearchResult>>{};

    for (final result in results) {
      groups.putIfAbsent(result.category, () => []).add(result);
    }
    final orderedCategories = groups.keys.toList()
      ..sort((left, right) {
        final leftScore = groups[left]!
            .map((result) => result.relevanceScore)
            .reduce((a, b) => a > b ? a : b);
        final rightScore = groups[right]!
            .map((result) => result.relevanceScore)
            .reduce((a, b) => a > b ? a : b);
        return rightScore.compareTo(leftScore);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedCategory != SearchCategory.all)
          _FilteredResultsHeader(
            category: selectedCategory,
            count: results.length,
          )
        else
          Text(
            '${results.length} ${results.length == 1 ? 'result' : 'results'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

        AppSpacing.gapMd,

        for (final category in orderedCategories)
          if (groups[category]?.isNotEmpty == true) ...[
            if (selectedCategory == SearchCategory.all) ...[
              _SearchGroupHeader(
                category: category,
                count: groups[category]!.length,
              ),

              AppSpacing.gapSm,
            ],

            for (var index = 0; index < groups[category]!.length; index++) ...[
              _SearchResultTile(result: groups[category]![index], query: query),

              if (index != groups[category]!.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],

            AppSpacing.gapLg,
          ],
      ],
    );
  }
}

class _FilteredResultsHeader extends StatelessWidget {
  const _FilteredResultsHeader({required this.category, required this.count});

  final SearchCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          _SearchResultTile.iconFor(category),
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            category.displayName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SearchGroupHeader extends StatelessWidget {
  const _SearchGroupHeader({required this.category, required this.count});

  final SearchCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              _SearchResultTile.iconFor(category),
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          AppSpacing.hGapSm,

          Expanded(
            child: Text(
              category == SearchCategory.outbreaks
                  ? 'Outbreaks · Top results'
                  : category.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends ConsumerWidget {
  const _SearchResultTile({required this.result, required this.query});

  final SearchResult result;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final outbreak = result.getItem<PublicOutbreak>();
    final outbreakTone = outbreak == null
        ? null
        : outbreak.status.toLowerCase() == 'active'
        ? colors.error
        : colors.tertiary;

    final canOpen =
        result.route?.trim().isNotEmpty == true ||
        result.externalUrl?.trim().isNotEmpty == true;

    return Semantics(
      button: canOpen,
      enabled: canOpen,
      label: '${result.title}. ${result.category.displayName}',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: outbreakTone?.withValues(alpha: 0.045),
        shape: outbreakTone == null
            ? null
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: outbreakTone.withValues(alpha: 0.28)),
              ),
        child: InkWell(
          onTap: !canOpen
              ? null
              : () async {
                  await ref
                      .read(globalSearchControllerProvider.notifier)
                      .recordSelection(result);
                  if (!context.mounted) return;
                  if (result.externalUrl case final String value) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Open external official resource?'),
                        content: Text(
                          'You are leaving MediGuide and opening:\n$value',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
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
                      await launchUrl(
                        Uri.parse(value),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                    return;
                  }
                  context.push(result.route!, extra: result.item);
                },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClinicalIconTile(icon: iconFor(result.category)),

                AppSpacing.hGapMd,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HighlightedText(
                        text: result.title,
                        query: query,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),

                      if (outbreak != null) ...[
                        const SizedBox(height: 7),
                        _OutbreakSearchBadge(
                          status: outbreak.status,
                          color: outbreakTone!,
                        ),
                      ],

                      const SizedBox(height: 5),

                      _SearchCategoryLabel(category: result.category),

                      if (result.subtitle?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 7),

                        _HighlightedText(
                          text: result.subtitle!,
                          query: query,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.35,
                              ),
                        ),
                      ],

                      if (result.description?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 7),
                        _HighlightedText(
                          text: result.description!,
                          query: query,
                          maxLines: 3,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(height: 1.35),
                        ),
                      ],

                      if (result.isOffline || result.isStale) ...[
                        const SizedBox(height: 8),
                        _SearchAvailabilityBadge(
                          offline: result.isOffline,
                          stale: result.isStale,
                        ),
                      ],
                    ],
                  ),
                ),

                if (canOpen) ...[
                  AppSpacing.hGapSm,

                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Icon(
                      LucideIcons.chevronRight,
                      color: colors.onSurfaceVariant,
                      size: 19,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData iconFor(SearchCategory category) {
    return switch (category) {
      SearchCategory.drugs => LucideIcons.pill,
      SearchCategory.guidelines => LucideIcons.bookOpenText,
      SearchCategory.consultants => LucideIcons.stethoscope,
      SearchCategory.healthFacilities => LucideIcons.hospital,
      SearchCategory.abbreviations => LucideIcons.languages,
      SearchCategory.faq => LucideIcons.circleHelp,
      SearchCategory.outbreaks => LucideIcons.siren,
      SearchCategory.outbreakDocuments => LucideIcons.files,
      SearchCategory.outbreakResources => LucideIcons.externalLink,
      SearchCategory.situationReports => LucideIcons.fileChartColumn,
      SearchCategory.tools => LucideIcons.calculator,
      SearchCategory.all => LucideIcons.search,
    };
  }
}

class _OutbreakSearchBadge extends StatelessWidget {
  const _OutbreakSearchBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = status.trim().isEmpty
        ? 'Published outbreak'
        : '${status[0].toUpperCase()}${status.substring(1)} outbreak';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SearchAvailabilityBadge extends StatelessWidget {
  const _SearchAvailabilityBadge({required this.offline, required this.stale});

  final bool offline;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          offline ? LucideIcons.cloudOff : LucideIcons.clock3,
          size: 13,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        Text(
          offline
              ? (stale
                    ? 'Offline cached result · may be stale'
                    : 'Offline cached result')
              : 'Cached result · verify online',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SearchCategoryLabel extends StatelessWidget {
  const _SearchCategoryLabel({required this.category});

  final SearchCategory category;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _SearchResultTile.iconFor(category),
            size: 11,
            color: colors.onSecondaryContainer,
          ),

          const SizedBox(width: 4),

          Text(
            category.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===========================================================================
/// HIGHLIGHTED SEARCH TEXT
/// ===========================================================================

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    this.maxLines,
    this.style,
  });

  final String text;
  final String query;
  final int? maxLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = query.trim();

    final normal = style ?? DefaultTextStyle.of(context).style;

    if (trimmedQuery.isEmpty) {
      return Text(
        text,
        style: normal,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final index = text.toLowerCase().indexOf(trimmedQuery.toLowerCase());

    if (index < 0) {
      return Text(
        text,
        style: normal,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final matchEnd = index + trimmedQuery.length;

    return Text.rich(
      TextSpan(
        style: normal,
        children: [
          if (index > 0) TextSpan(text: text.substring(0, index)),

          TextSpan(
            text: text.substring(index, matchEnd),
            style: normal.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          if (matchEnd < text.length) TextSpan(text: text.substring(matchEnd)),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// ===========================================================================
/// EMPTY / ERROR / LOADING STATE
/// ===========================================================================

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: loading
                    ? Padding(
                        padding: const EdgeInsets.all(21),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: colors.primary,
                        ),
                      )
                    : Icon(icon, size: 30, color: colors.primary),
              ),

              AppSpacing.gapMd,

              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),

              AppSpacing.gapSm,

              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),

              if (action != null) ...[AppSpacing.gapLg, action!],
            ],
          ),
        ),
      ),
    );
  }
}
