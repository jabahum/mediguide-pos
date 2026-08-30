part of '../screens/generic_viewer_page.dart';

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
