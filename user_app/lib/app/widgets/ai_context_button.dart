import 'package:flutter/material.dart';
import 'package:user_app/app/core/navigation/app_navigator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/models/ai_context.dart';
import '../core/navigation/app_router.dart';

/// Enhanced AI button widget that injects context into the AI assistant
/// Designed specifically for detail pages
class AiContextButton extends StatelessWidget {
  /// The context to pass to the AI assistant
  final AiContext context;

  /// Optional custom tooltip text
  final String? tooltip;

  /// Button style variant
  final AiButtonStyle style;

  const AiContextButton({
    super.key,
    required this.context,
    this.tooltip,
    this.style = AiButtonStyle.iconButton,
  });

  /// Create an icon button for app bars (most common usage)
  const AiContextButton.iconButton({
    super.key,
    required this.context,
    this.tooltip,
  }) : style = AiButtonStyle.iconButton;

  /// Create a floating action button variant
  const AiContextButton.fab({super.key, required this.context, this.tooltip})
    : style = AiButtonStyle.fab;

  /// Create an action card variant for special cases
  const AiContextButton.actionCard({
    super.key,
    required this.context,
    this.tooltip,
  }) : style = AiButtonStyle.actionCard;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case AiButtonStyle.iconButton:
        return _buildIconButton();
      case AiButtonStyle.fab:
        return _buildFab();
      case AiButtonStyle.actionCard:
        return _buildActionCard();
    }
  }

  /// Build icon button for app bars
  Widget _buildIconButton() {
    return IconButton(
      onPressed: _navigateToAI,
      icon: const Icon(LucideIcons.sparkles),
      tooltip: tooltip ?? _getDefaultTooltip(),
    );
  }

  /// Build floating action button
  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _navigateToAI,
      tooltip: tooltip ?? _getDefaultTooltip(),
      child: const Icon(LucideIcons.sparkles),
    );
  }

  /// Build action card for special layouts
  Widget _buildActionCard() {
    return Card(
      child: ListTile(
        leading: const Icon(LucideIcons.sparkles),
        title: Text(tooltip ?? 'Ask AI Assistant'),
        subtitle: Text(
          'Get help with ${context.sourceType.label.toLowerCase()}',
        ),
        onTap: _navigateToAI,
        trailing: const Icon(LucideIcons.chevronRight),
      ),
    );
  }

  /// Navigate to AI assistant with context
  void _navigateToAI() {
    AppNavigator.pushNamed(
      AppRoutes.aiAssistant,
      arguments: {'aiContext': context.toJson()},
    );
  }

  /// Get default tooltip based on context type
  String _getDefaultTooltip() {
    switch (context.sourceType) {
      case AiContextType.guideline:
        return 'Ask AI about this guideline';
      case AiContextType.drug:
        return 'Ask AI about this medication';
      case AiContextType.calculator:
        return 'Get AI help with this calculator';
      case AiContextType.tool:
        return 'Ask AI about this tool';
      case AiContextType.consultant:
        return 'Ask AI about this consultant';
      case AiContextType.facility:
        return 'Ask AI about this facility';
      case AiContextType.faq:
        return 'Get more AI help on this topic';
      case AiContextType.genericPage:
        return 'Ask AI about this content';
      case AiContextType.unknown:
        return 'Ask AI Assistant';
    }
  }
}

/// Button style variants for different use cases
enum AiButtonStyle {
  /// Icon button for app bars (default)
  iconButton,

  /// Floating action button
  fab,

  /// Action card for special layouts
  actionCard,
}

/// Extension methods for easy context creation
extension AiContextButtonHelpers on Widget {
  /// Add an AI context button to an app bar
  static Widget appBarButton({required AiContext context, String? tooltip}) {
    return AiContextButton.iconButton(context: context, tooltip: tooltip);
  }

  /// Create a floating AI button
  static Widget floatingButton({required AiContext context, String? tooltip}) {
    return AiContextButton.fab(context: context, tooltip: tooltip);
  }
}

/// Helper class for quick context creation in common scenarios
class QuickAiContext {
  /// Quick context for guideline pages
  static AiContext guideline({
    required String title,
    required String content,
    String? id,
  }) {
    return AiContext.guideline(title: title, content: content, guidelineId: id);
  }

  /// Quick context for generic pages
  static AiContext genericPage({
    required String title,
    required String content,
    String? id,
  }) {
    return AiContext.genericPage(title: title, content: content, pageId: id);
  }

  /// Quick context for drug pages
  static AiContext drug({
    required String name,
    required String content,
    String? id,
  }) {
    return AiContext.drug(drugName: name, content: content, drugId: id);
  }

  /// Quick context for calculator pages
  static AiContext calculator({
    required String name,
    required String description,
    String? id,
  }) {
    return AiContext.calculator(
      calculatorName: name,
      content: description,
      calculatorId: id,
    );
  }
}
