import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/features/search/presentation/controllers/global_search_controller.dart';
import 'package:user_app/shared/models/search_models.dart';

class GlobalSearchPage extends ConsumerStatefulWidget {
  const GlobalSearchPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends ConsumerState<GlobalSearchPage> {
  final _controller = TextEditingController();
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
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => ref.read(globalSearchControllerProvider.notifier).search(value),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(globalSearchControllerProvider);
    final visible = _category == SearchCategory.all
        ? state.results
        : state.results
              .where((result) => result.category == _category)
              .toList(growable: false);
    final body = SafeArea(
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: AppSpacing.pagePadding.copyWith(bottom: 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  AppSpacing.gapMd,
                  SearchBar(
                    controller: _controller,
                    hintText: 'Search guidelines, drugs, tools…',
                    leading: const Icon(LucideIcons.search),
                    trailing: [
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _controller.clear();
                            ref
                                .read(globalSearchControllerProvider.notifier)
                                .clear();
                            setState(() {});
                          },
                          icon: const Icon(LucideIcons.x),
                        ),
                    ],
                    onChanged: _search,
                    onSubmitted: (value) {
                      _debounce?.cancel();
                      ref
                          .read(globalSearchControllerProvider.notifier)
                          .search(value);
                    },
                  ),
                  AppSpacing.gapMd,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final category in SearchCategory.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category.displayName),
                              selected: category == _category,
                              onSelected: (_) =>
                                  setState(() => _category = category),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.gapMd,
                ],
              ),
            ),
          ),
          if (state.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.hasError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _SearchMessage(
                icon: LucideIcons.triangleAlert,
                title: 'Search unavailable',
                message: 'Check your connection and try again.',
                action: FilledButton(
                  onPressed: () => ref
                      .read(globalSearchControllerProvider.notifier)
                      .search(_controller.text),
                  child: const Text('Retry'),
                ),
              ),
            )
          else if (!state.hasQuery)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _SearchMessage(
                icon: LucideIcons.search,
                title: 'Find clinical guidance',
                message:
                    'Search across guidelines, drugs, abbreviations, tools and services.',
              ),
            )
          else if (state.validationMessage.isNotEmpty || visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _SearchMessage(
                icon: LucideIcons.fileSearch,
                title: visible.isEmpty ? 'No results found' : 'Keep typing',
                message: state.validationMessage.isNotEmpty
                    ? state.validationMessage
                    : 'Try a broader term or another category.',
              ),
            )
          else
            SliverPadding(
              padding: AppSpacing.pagePadding.copyWith(top: 0),
              sliver: SliverToBoxAdapter(
                child: _GroupedSearchResults(
                  results: visible,
                  query: state.query,
                ),
              ),
            ),
        ],
      ),
    );
    return widget.embedded ? body : Scaffold(body: body);
  }
}

class _GroupedSearchResults extends StatelessWidget {
  const _GroupedSearchResults({required this.results, required this.query});

  final List<SearchResult> results;
  final String query;

  @override
  Widget build(BuildContext context) {
    final groups = <SearchCategory, List<SearchResult>>{};
    for (final result in results) {
      groups.putIfAbsent(result.category, () => []).add(result);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${results.length} ${results.length == 1 ? 'result' : 'results'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        AppSpacing.gapMd,
        for (final category in SearchCategory.values)
          if (groups[category]?.isNotEmpty == true) ...[
            Semantics(
              header: true,
              child: Text(
                category.displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            AppSpacing.gapSm,
            for (final result in groups[category]!) ...[
              _SearchResultTile(result: result, query: query),
              const SizedBox(height: 8),
            ],
            AppSpacing.gapMd,
          ],
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.query});

  final SearchResult result;
  final String query;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: ListTile(
      leading: CircleAvatar(child: Icon(_icon(result.category), size: 20)),
      title: _HighlightedText(text: result.title, query: query),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.category.displayName),
          if ((result.subtitle ?? result.description)?.isNotEmpty == true)
            _HighlightedText(
              text: result.subtitle ?? result.description!,
              query: query,
              maxLines: 2,
            ),
        ],
      ),
      trailing: const Icon(LucideIcons.chevronRight),
      onTap: result.route == null
          ? null
          : () => context.push(result.route!, extra: result.item),
    ),
  );

  static IconData _icon(SearchCategory category) => switch (category) {
    SearchCategory.drugs => LucideIcons.pill,
    SearchCategory.guidelines => LucideIcons.bookOpenText,
    SearchCategory.consultants => LucideIcons.stethoscope,
    SearchCategory.healthFacilities => LucideIcons.hospital,
    SearchCategory.abbreviations => LucideIcons.languages,
    SearchCategory.faq => LucideIcons.circleHelp,
    SearchCategory.tools => LucideIcons.calculator,
    SearchCategory.all => LucideIcons.search,
  };
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    this.maxLines,
  });
  final String text;
  final String query;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final index = text.toLowerCase().indexOf(query.toLowerCase());
    if (index < 0 || query.isEmpty) {
      return Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    final normal = DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(
        style: normal,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: normal.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
          AppSpacing.gapMd,
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          AppSpacing.gapSm,
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[AppSpacing.gapMd, action!],
        ],
      ),
    ),
  );
}
