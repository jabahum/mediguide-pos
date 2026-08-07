import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/all_actions/presentation/controllers/all_actions_controller.dart';

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
class _ScrollableStateContainer extends StatelessWidget {
  const _ScrollableStateContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
        child,
      ],
    );
  }
}

class _InlineContentError extends StatelessWidget {
  const _InlineContentError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.triangleAlert, color: cs.onErrorContainer),
          AppSpacing.sm.gap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Additional content unavailable',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: cs.onErrorContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ActionsHeaderCard extends StatelessWidget {
  const _ActionsHeaderCard({
    required this.clinicalToolsCount,
    required this.referencesCount,
    required this.contentCount,
  });

  final int clinicalToolsCount;
  final int referencesCount;
  final int contentCount;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final total = clinicalToolsCount + referencesCount + contentCount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cs.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: cs.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(LucideIcons.layoutGrid, color: cs.primary, size: 28),
          ),

          AppSpacing.md.gap,

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Actions',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quick access to everything you can do in MediGuide.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _CountChip(label: '$total total', icon: LucideIcons.layers),
                    if (clinicalToolsCount > 0)
                      _CountChip(
                        label: '$clinicalToolsCount tools',
                        icon: LucideIcons.stethoscope,
                      ),
                    if (referencesCount > 0)
                      _CountChip(
                        label: '$referencesCount reference',
                        icon: LucideIcons.sparkles,
                      ),
                    if (contentCount > 0)
                      _CountChip(
                        label: '$contentCount pages',
                        icon: LucideIcons.files,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, subtitle: subtitle, icon: icon),

        AppSpacing.sm.gap,

        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  children[index],
                  if (index != children.length - 1)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: cs.primary, size: 20),
        ),

        AppSpacing.sm.gap,

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 21),
      ),
      title: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      ),
      trailing: Icon(LucideIcons.chevronRight, color: cs.onSurfaceVariant),
    );
  }
}
