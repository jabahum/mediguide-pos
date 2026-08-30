part of '../screens/generic_viewer_page.dart';

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
