part of '../screens/generic_viewer_page.dart';

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
