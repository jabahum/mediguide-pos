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
      if (!mounted) {
        return;
      }

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

    // =====================================================
    // LOADING
    // =====================================================

    if (state.isLoading) {
      return const Scaffold(
        body: AppLoadingView(message: 'Loading content...'),
      );
    }

    // =====================================================
    // ERROR
    // =====================================================

    if (state.errorMessage != null && state.page == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(state.pageTitle, style: context.textTheme.titleMedium),
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

    // =====================================================
    // EMPTY
    // =====================================================

    if (!state.hasContent) {
      return Scaffold(
        appBar: AppBar(
          title: Text(state.pageTitle, style: context.textTheme.titleMedium),
        ),
        body: EmptyState.noData(
          title: 'No Content Available',
          description: 'This page does not have any content to display.',
        ),
      );
    }

    // =====================================================
    // KEY / VALUE PAGE
    // =====================================================

    if (state.isKeyValueContent) {
      return _KeyValuePage(
        state: state,
        controller: controller,
        contextService: contextService,
      );
    }

    // =====================================================
    // STANDARD HTML PAGE
    // =====================================================

    return _HtmlPage(
      state: state,
      controller: controller,
      contextService: contextService,
    );
  }
}

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

    // Avoid DefaultTabController(length: 0).
    if (sections.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(state.pageTitle, style: context.textTheme.titleMedium),
        ),
        body: EmptyState.noData(
          title: 'No Sections Available',
          description: 'This page does not contain any sections to display.',
        ),
      );
    }

    return DefaultTabController(
      length: sections.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.pageTitle, style: context.textTheme.titleMedium),
          actions: [
            AiContextButton.iconButton(
              context: _buildPageContext(state, contextService),
            ),
            IconButton(
              onPressed: controller.sharePage,
              icon: const Icon(LucideIcons.share),
              tooltip: 'Share',
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final section in sections) Tab(text: section.title)],
            onTap: (index) {
              controller.navigateToSection(sections[index]);
            },
          ),
        ),
        body: ListView(
          controller: controller.scrollController,
          padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
          children: [
            if (state.page?.description?.trim().isNotEmpty == true) ...[
              Text(
                state.page!.description!,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.justify,
              ),
              AppSpacing.lg.gap,
            ],

            for (final section in sections)
              GenericPageSectionWidget(
                key: controller.getSectionKey(section),
                section: section,
              ),

            AppSpacing.xxl.gap,
          ],
        ),
      ),
    );
  }
}

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
      appBar: AppBar(
        title: Text(state.pageTitle, style: context.textTheme.titleMedium),
        actions: [
          AiContextButton.iconButton(
            context: _buildPageContext(state, contextService),
          ),
          IconButton(
            onPressed: controller.sharePage,
            icon: const Icon(LucideIcons.share),
            tooltip: 'Share',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
        children: [
          if (state.page?.description?.trim().isNotEmpty == true) ...[
            Text(
              state.page!.description!,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            ),
            AppSpacing.lg.gap,
          ],

          Html(data: state.stringContent, style: HtmlStyles.content(context)),

          AppSpacing.xxl.gap,
        ],
      ),
    );
  }
}

// ======================================================
// AI CONTEXT
// ======================================================

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
