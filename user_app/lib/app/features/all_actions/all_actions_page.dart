import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../utils/app_spacing.dart';
import '../../utils/loading.dart';
import './all_actions_controller.dart';

class AllActionsPage extends ConsumerWidget {
  const AllActionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(allActionsControllerProvider);
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
      body: Builder(
        builder: (context) {
          final clinicalTools = controller.actionsByCategory(
            ActionCategory.clinicalTools,
          );
          final aiAndReference = controller.actionsByCategory(
            ActionCategory.aiAndReference,
          );
          final genericPages = controller.genericPages;

          final hasAnyContent =
              clinicalTools.isNotEmpty ||
              aiAndReference.isNotEmpty ||
              genericPages.isNotEmpty ||
              controller.isLoadingPages;

          if (!hasAnyContent) {
            return _EmptyActionsState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (controller.isLoadingPages) return;
              await controller.reloadData();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _ActionsHeaderCard(
                  clinicalToolsCount: clinicalTools.length,
                  referencesCount: aiAndReference.length,
                  contentCount: genericPages.length,
                ),

                AppSpacing.lg.gap,

                if (clinicalTools.isNotEmpty) ...[
                  _ActionsSection(
                    title: 'Clinical Tools',
                    subtitle: 'Calculators, checklists and clinical utilities',
                    icon: LucideIcons.stethoscope,
                    children: clinicalTools.map((action) {
                      return _ActionTile(
                        icon: action.icon,
                        iconColor: action.color,
                        title: action.title,
                        subtitle: action.subtitle,
                        onTap: action.onTap,
                      );
                    }).toList(),
                  ),
                  AppSpacing.lg.gap,
                ],

                if (aiAndReference.isNotEmpty) ...[
                  _ActionsSection(
                    title: 'AI & Reference',
                    subtitle: 'Search, guidance and clinical reference tools',
                    icon: LucideIcons.sparkles,
                    children: aiAndReference.map((action) {
                      return _ActionTile(
                        icon: action.icon,
                        iconColor: action.color,
                        title: action.title,
                        subtitle: action.subtitle,
                        onTap: action.onTap,
                      );
                    }).toList(),
                  ),
                  AppSpacing.lg.gap,
                ],

                if (controller.isLoadingPages)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: CenteredLoading(loading: Loading.medium()),
                  ),

                if (genericPages.isNotEmpty) ...[
                  _ActionsSection(
                    title: 'Additional Content',
                    subtitle: 'Helpful pages and information',
                    icon: LucideIcons.files,
                    children: genericPages.map((page) {
                      return _ActionTile(
                        icon: LucideIcons.fileText,
                        iconColor: Colors.blueGrey,
                        title: page.title,
                        subtitle: page.description ?? 'Tap to view content',
                        onTap: () => controller.openGenericPage(page),
                      );
                    }).toList(),
                  ),
                  AppSpacing.lg.gap,
                ],

                AppSpacing.xxxl.gap,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionsHeaderCard extends StatelessWidget {
  final int clinicalToolsCount;
  final int referencesCount;
  final int contentCount;

  const _ActionsHeaderCard({
    required this.clinicalToolsCount,
    required this.referencesCount,
    required this.contentCount,
  });

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
  final String label;
  final IconData icon;

  const _CountChip({required this.label, required this.icon});

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
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const _ActionsSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

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
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1)
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
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

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
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

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

class _EmptyActionsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        Center(
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  LucideIcons.layoutGrid,
                  color: cs.primary,
                  size: 36,
                ),
              ),
              AppSpacing.md.gap,
              Text(
                'No actions available',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Actions will appear here when they are available.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
