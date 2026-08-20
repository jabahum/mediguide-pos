import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/ai_assistant/data/models/ai_context.dart';
import 'package:user_app/features/ai_assistant/data/services/ai_context_service.dart';
import 'package:user_app/features/content/data/models/generic_page.dart';
import 'package:user_app/features/content/presentation/controllers/generic_viewer_controller.dart';
import 'package:user_app/features/content/presentation/controllers/generic_viewer_state.dart';
import 'package:user_app/features/content/presentation/widgets/generic_page_section.dart';

import 'package:user_app/shared/widgets/ai_context_button.dart';
import 'package:user_app/shared/widgets/html_styles.dart';

class GenericViewerPage extends ConsumerStatefulWidget {
  const GenericViewerPage({super.key, this.argument, this.pageKey});

  final Object? argument;
  final String? pageKey;

  @override
  ConsumerState<GenericViewerPage> createState() => _GenericViewerPageState();
}

class _GenericViewerPageState extends ConsumerState<GenericViewerPage> {
  @override
  void initState() {
    super.initState();

    final argument = widget.argument;
    final pageKey = widget.pageKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref
          .read(genericViewerControllerProvider.notifier)
          .initialize(pageArgument: argument, pageKey: pageKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(genericViewerControllerProvider);

    final controller = ref.read(genericViewerControllerProvider.notifier);

    final contextService = ref.watch(aiContextServiceProvider);

    // =====================================================================
    // LOADING
    // =====================================================================

    if (state.isLoading) {
      return const Scaffold(
        body: AppLoadingView(message: 'Loading content...'),
      );
    }

    // =====================================================================
    // ERROR
    // =====================================================================

    if (state.errorMessage != null && state.page == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            state.pageTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: AppErrorView(
          error: state.errorMessage!,
          title: 'Unable to load content',
          message: 'This page could not be loaded. Please try again.',
          onRetry: () {
            controller.initialize(
              pageArgument: widget.argument,
              pageKey: widget.pageKey,
            );
          },
        ),
      );
    }

    // =====================================================================
    // EMPTY
    // =====================================================================

    if (!state.hasContent) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            state.pageTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: EmptyState.noData(
          title: 'No content available',
          description: 'This page does not have any content to display.',
        ),
      );
    }

    // =====================================================================
    // CONTENT
    // =====================================================================

    if (state.isKeyValueContent) {
      return _KeyValuePage(
        state: state,
        controller: controller,
        contextService: contextService,
      );
    }

    return _HtmlPage(
      state: state,
      controller: controller,
      contextService: contextService,
    );
  }
}

// ===========================================================================
// KEY / VALUE PAGE
// ===========================================================================

class _KeyValuePage extends StatelessWidget {
  const _KeyValuePage({
    required this.state,
    required this.controller,
    required this.contextService,
  });

  final GenericViewerState state;
  final GenericViewerController controller;
  final AiContextService contextService;

  @override
  Widget build(BuildContext context) {
    final sections = state.availableSections;

    if (sections.isEmpty) {
      return Scaffold(
        appBar: _ViewerAppBar(
          state: state,
          controller: controller,
          contextService: contextService,
        ),
        body: EmptyState.noData(
          title: 'No sections available',
          description: 'This page does not contain any sections to display.',
        ),
      );
    }

    return Scaffold(
      appBar: _ViewerAppBar(
        state: state,
        controller: controller,
        contextService: contextService,
      ),
      body: Column(
        children: [
          // =================================================================
          // SECTION NAVIGATION
          // =================================================================
          _SectionNavigation(
            sections: sections,
            onSelected: controller.navigateToSection,
          ),

          // =================================================================
          // CONTENT
          // =================================================================
          Expanded(
            child: ListView(
              controller: controller.scrollController,
              padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context),
                AppSpacing.lg,
                Responsive.horizontalPadding(context),
                AppSpacing.xxxl,
              ),
              children: [
                if (state.page?.description?.trim().isNotEmpty == true) ...[
                  _PageDescription(description: state.page!.description!),
                  AppSpacing.gapLg,
                ],

                for (final section in sections) ...[
                  GenericPageSectionWidget(
                    key: controller.getSectionKey(section),
                    section: section,
                  ),
                  AppSpacing.gapLg,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// HTML PAGE
// ===========================================================================

class _HtmlPage extends StatelessWidget {
  const _HtmlPage({
    required this.state,
    required this.controller,
    required this.contextService,
  });

  final GenericViewerState state;
  final GenericViewerController controller;
  final AiContextService contextService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _ViewerAppBar(
        state: state,
        controller: controller,
        contextService: contextService,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          Responsive.horizontalPadding(context),
          AppSpacing.lg,
          Responsive.horizontalPadding(context),
          AppSpacing.xxxl,
        ),
        children: [
          if (state.page?.description?.trim().isNotEmpty == true) ...[
            _PageDescription(description: state.page!.description!),
            AppSpacing.gapLg,
          ],

          _HtmlContentCard(html: state.stringContent),
        ],
      ),
    );
  }
}

// ===========================================================================
// APP BAR
// ===========================================================================

class _ViewerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ViewerAppBar({
    required this.state,
    required this.controller,
    required this.contextService,
  });

  final GenericViewerState state;
  final GenericViewerController controller;
  final AiContextService contextService;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      titleSpacing: AppSpacing.md,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.pageTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (state.page?.description?.trim().isNotEmpty == true)
            Text(
              'MediGuide reference content',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
        ],
      ),
      actions: [
        AiContextButton.iconButton(
          context: _buildPageContext(state, contextService),
        ),
        IconButton(
          tooltip: 'Share',
          onPressed: controller.sharePage,
          icon: const Icon(LucideIcons.share2),
        ),
        AppSpacing.hGapXs,
      ],
    );
  }
}

// ===========================================================================
// SECTION NAVIGATION
// ===========================================================================

class _SectionNavigation extends StatelessWidget {
  const _SectionNavigation({required this.sections, required this.onSelected});

  final List<GenericPageSection> sections;
  final ValueChanged<GenericPageSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: sections.length,
        separatorBuilder: (_, _) => AppSpacing.hGapSm,
        itemBuilder: (context, index) {
          final section = sections[index];

          return ActionChip(
            avatar: const Icon(LucideIcons.listTree, size: 15),
            label: Text(
              section.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: () {
              onSelected(section);
            },
          );
        },
      ),
    );
  }
}

// ===========================================================================
// PAGE DESCRIPTION
// ===========================================================================

class _PageDescription extends StatelessWidget {
  const _PageDescription({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.info, size: 18, color: colors.primary),
          ),

          AppSpacing.hGapMd,

          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// HTML CONTENT
// ===========================================================================

class _HtmlContentCard extends StatelessWidget {
  const _HtmlContentCard({required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Html(data: html, style: HtmlStyles.content(context)),
    );
  }
}

// ===========================================================================
// AI CONTEXT
// ===========================================================================

AiContext _buildPageContext(
  GenericViewerState state,
  AiContextService contextService,
) {
  final page = state.page;

  if (page == null) {
    return QuickAiContext.genericPage(
      title: state.pageTitle,
      content: 'No content available',
    );
  }

  final content = state.isKeyValueContent
      ? contextService.cleanHtmlContent(
          state.availableSections
              .map((section) => '${section.title}: ${section.content}')
              .join('\n\n'),
        )
      : contextService.cleanHtmlContent(state.stringContent);

  return contextService.extractGenericPageContext(
    title: page.title,
    content: content,
    description: page.description,
    pageId: page.id,
  );
}
