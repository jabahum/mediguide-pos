part of '../screens/generic_viewer_page.dart';

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
