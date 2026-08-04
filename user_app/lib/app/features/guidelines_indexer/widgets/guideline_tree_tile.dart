import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/app/data/models/guideline_index.dart';
import 'package:user_app/app/utils/responsive.dart';

/// Custom tree tile widget for guideline items
class GuidelineTreeTile extends StatelessWidget {
  final TreeNode<GuidelineIndex> node;

  const GuidelineTreeTile({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final nodeData = node.data!;
    final hasChildren = node.childrenAsList.isNotEmpty;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.responsiveHorizontalPadding,
        vertical: 8,
      ),
      title: Text(
        nodeData.title,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: hasChildren ? FontWeight.w600 : FontWeight.w500,
          color: hasChildren
              ? context.theme.colorScheme.onSurface
              : context.theme.colorScheme.onSurface,
        ),
      ),
      subtitle: nodeData.description.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                nodeData.description,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.theme.colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : null,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: hasChildren
              ? context.theme.colorScheme.primaryContainer
              : context.theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          hasChildren ? LucideIcons.folder : LucideIcons.fileText,
          color: hasChildren
              ? context.theme.colorScheme.primary
              : context.theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      trailing: hasChildren
          ? null // ExpansionIndicator will handle this
          : Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
    );
  }
}
