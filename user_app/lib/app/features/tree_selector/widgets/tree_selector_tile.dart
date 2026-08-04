import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../utils/responsive.dart';
import '../models/tree_selector_models.dart';

class TreeSelectorTile extends StatelessWidget {
  final TreeNode<TreeSelectorNodeModel> node;
  final bool isNodeLoading;
  final bool showParentSelectAction;
  final VoidCallback? onSelectParent;

  const TreeSelectorTile({
    super.key,
    required this.node,
    this.isNodeLoading = false,
    this.showParentSelectAction = false,
    this.onSelectParent,
  });

  @override
  Widget build(BuildContext context) {
    final data = node.data;
    if (data == null) return const SizedBox.shrink();

    final cs = context.theme.colorScheme;
    final hasChildren = data.hasChildren;
    final subtitle = _buildSubtitle(data);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: false,
        minVerticalPadding: 8,
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.responsiveHorizontalPadding,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: _NodeIcon(hasChildren: hasChildren, isLoading: isNodeLoading),
        title: Text(
          data.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: hasChildren ? FontWeight.w700 : FontWeight.w600,
            height: 1.25,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ),
        trailing: _TileTrailing(
          hasChildren: hasChildren,
          isLoading: isNodeLoading,
          showParentSelectAction: showParentSelectAction,
          onSelectParent: onSelectParent,
        ),
      ),
    );
  }

  String? _buildSubtitle(TreeSelectorNodeModel data) {
    final parts = <String>[];

    if (data.subtitle.trim().isNotEmpty) {
      parts.add(data.subtitle.trim());
    }

    if (data.count > 0) {
      parts.add('${data.count} ${data.count == 1 ? 'item' : 'items'}');
    }

    if (parts.isEmpty) return null;

    return parts.join(' • ');
  }
}

class _NodeIcon extends StatelessWidget {
  final bool hasChildren;
  final bool isLoading;

  const _NodeIcon({required this.hasChildren, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    final bgColor = hasChildren
        ? cs.primaryContainer
        : cs.surfaceContainerHighest;

    final iconColor = hasChildren ? cs.primary : cs.onSurfaceVariant;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            : Icon(
                hasChildren ? LucideIcons.folderTree : LucideIcons.fileText,
                size: 20,
                color: iconColor,
              ),
      ),
    );
  }
}

class _TileTrailing extends StatelessWidget {
  final bool hasChildren;
  final bool isLoading;
  final bool showParentSelectAction;
  final VoidCallback? onSelectParent;

  const _TileTrailing({
    required this.hasChildren,
    required this.isLoading,
    required this.showParentSelectAction,
    this.onSelectParent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    if (isLoading) {
      return const SizedBox(width: 40);
    }

    if (showParentSelectAction) {
      return IconButton(
        tooltip: 'done'.tr,
        onPressed: onSelectParent,
        icon: Icon(LucideIcons.check, color: cs.primary),
      );
    }

    return Icon(
      hasChildren ? LucideIcons.chevronDown : LucideIcons.chevronRight,
      size: 18,
      color: cs.onSurfaceVariant,
    );
  }
}
