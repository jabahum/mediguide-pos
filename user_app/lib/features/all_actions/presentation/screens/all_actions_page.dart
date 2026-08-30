import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/all_actions/presentation/controllers/all_actions_controller.dart';

part '../widgets/all_actions_page_scrollable_state_container.dart';
part '../widgets/all_actions_page_inline_content_error.dart';
part '../widgets/all_actions_page_actions_header_card.dart';
part '../widgets/all_actions_page_count_chip.dart';
part '../widgets/all_actions_page_actions_section.dart';
part '../widgets/all_actions_page_section_header.dart';
part '../widgets/all_actions_page_action_tile.dart';

class AllActionsPage extends ConsumerWidget {
  const AllActionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(allActionsControllerProvider);

    final controller = ref.read(allActionsControllerProvider.notifier);

    final clinicalTools = controller.actionsByCategory(
      ActionCategory.clinicalTools,
    );

    final aiAndReference = controller.actionsByCategory(
      ActionCategory.aiAndReference,
    );

    final genericPages = state.genericPages;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Text(
          'All Actions',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (state.isLoadingPages) {
            return;
          }

          await controller.reloadData();
        },
        child: _buildContent(
          context: context,
          state: state,
          controller: controller,
          clinicalTools: clinicalTools,
          aiAndReference: aiAndReference,
          genericPages: genericPages,
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required AllActionsState state,
    required AllActionsController controller,
    required List<AppAction> clinicalTools,
    required List<AppAction> aiAndReference,
    required List<dynamic> genericPages,
  }) {
    final hasStaticContent =
        clinicalTools.isNotEmpty || aiAndReference.isNotEmpty;

    final hasDynamicContent = genericPages.isNotEmpty;

    // =====================================================
    // INITIAL LOADING
    // =====================================================

    if (state.isLoadingPages && !hasStaticContent && !hasDynamicContent) {
      return const _ScrollableStateContainer(
        child: AppLoadingView(message: 'Loading available actions...'),
      );
    }

    // =====================================================
    // ERROR
    // =====================================================

    if (state.errorMessage != null && !hasStaticContent && !hasDynamicContent) {
      return _ScrollableStateContainer(
        child: AppErrorView(
          error: state.errorMessage!,
          title: 'Unable to load actions',
          message: 'We could not load the available MediGuide actions.',
          onRetry: () {
            controller.reloadData();
          },
        ),
      );
    }

    // =====================================================
    // EMPTY
    // =====================================================

    if (!hasStaticContent && !hasDynamicContent && !state.isLoadingPages) {
      return _ScrollableStateContainer(
        child: EmptyState.noData(
          title: 'No actions available',
          description: 'Actions will appear here when they are available.',
          actionLabel: 'Refresh',
          onAction: () {
            controller.reloadData();
          },
        ),
      );
    }

    // =====================================================
    // CONTENT
    // =====================================================

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _ActionsHeaderCard(
          clinicalToolsCount: clinicalTools.length,
          referencesCount: aiAndReference.length,
          contentCount: genericPages.length,
        ),

        AppSpacing.lg.gap,

        // =================================================
        // CLINICAL TOOLS
        // =================================================
        if (clinicalTools.isNotEmpty) ...[
          _ActionsSection(
            title: 'Clinical Tools',
            subtitle: 'Calculators, checklists and clinical utilities',
            icon: LucideIcons.stethoscope,
            children: clinicalTools
                .map(
                  (action) => _ActionTile(
                    icon: action.icon,
                    iconColor: action.color,
                    title: action.title,
                    subtitle: action.subtitle,
                    onTap: action.onTap,
                  ),
                )
                .toList(growable: false),
          ),
          AppSpacing.lg.gap,
        ],

        // =================================================
        // AI AND REFERENCE
        // =================================================
        if (aiAndReference.isNotEmpty) ...[
          _ActionsSection(
            title: 'AI & Reference',
            subtitle: 'Search, guidance and clinical reference tools',
            icon: LucideIcons.sparkles,
            children: aiAndReference
                .map(
                  (action) => _ActionTile(
                    icon: action.icon,
                    iconColor: action.color,
                    title: action.title,
                    subtitle: action.subtitle,
                    onTap: action.onTap,
                  ),
                )
                .toList(growable: false),
          ),
          AppSpacing.lg.gap,
        ],

        // =================================================
        // INLINE DYNAMIC CONTENT ERROR
        // =================================================
        if (state.errorMessage != null && hasStaticContent) ...[
          _InlineContentError(
            message: state.errorMessage!,
            onRetry: () {
              controller.reloadData();
            },
          ),
          AppSpacing.lg.gap,
        ],

        // =================================================
        // DYNAMIC CONTENT LOADING
        // =================================================
        if (state.isLoadingPages && genericPages.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: AppLoadingView(message: 'Loading additional content...'),
          ),
          AppSpacing.lg.gap,
        ],

        // =================================================
        // ADDITIONAL CONTENT
        // =================================================
        if (genericPages.isNotEmpty) ...[
          _ActionsSection(
            title: 'Additional Content',
            subtitle: 'Helpful pages and information',
            icon: LucideIcons.files,
            children: genericPages
                .map(
                  (page) => _ActionTile(
                    icon: LucideIcons.fileText,
                    iconColor: Colors.blueGrey,
                    title: page.title,
                    subtitle: page.description ?? 'Tap to view content',
                    onTap: () {
                      controller.openGenericPage(page);
                    },
                  ),
                )
                .toList(growable: false),
          ),
          AppSpacing.lg.gap,
        ],

        AppSpacing.xxxl.gap,
      ],
    );
  }
}

/// Allows pull-to-refresh even for loading/error/empty pages.
