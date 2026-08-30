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

part '../widgets/global_search_page_widgets.dart';

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
