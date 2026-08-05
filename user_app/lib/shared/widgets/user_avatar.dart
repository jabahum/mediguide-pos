import 'package:flutter/material.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:universal_image/universal_image.dart';
import 'package:user_app/core/utils/loading.dart';
import 'package:user_app/core/utils/responsive.dart';

/// A unified avatar component that can display images or initials
/// with customizable dimensions and edit functionality
class UserAvatar extends StatelessWidget {
  /// The user's name for generating initials
  final String name;

  /// The avatar image URL
  final String? avatarUrl;

  /// The radius of the avatar (width and height will be radius * 2)
  final double radius;

  /// Whether to show an edit button overlay
  final bool showEditButton;

  /// Callback when edit button is pressed
  final VoidCallback? onEdit;

  /// Whether to show loading state
  final bool isLoading;

  /// Background color when showing initials (optional, uses theme color if null)
  final Color? backgroundColor;

  /// Text color for initials (optional, uses theme color if null)
  final Color? textColor;

  /// Border color (optional)
  final Color? borderColor;

  /// Border width
  final double borderWidth;

  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 28.0,
    this.showEditButton = false,
    this.onEdit,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth = 0.0,
  });

  /// Small avatar (radius: 20)
  const UserAvatar.small({
    super.key,
    required this.name,
    this.avatarUrl,
    this.showEditButton = false,
    this.onEdit,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth = 0.0,
  }) : radius = 20.0;

  /// Medium avatar (radius: 28) - default
  const UserAvatar.medium({
    super.key,
    required this.name,
    this.avatarUrl,
    this.showEditButton = false,
    this.onEdit,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth = 0.0,
  }) : radius = 28.0;

  /// Large avatar (radius: 40)
  const UserAvatar.large({
    super.key,
    required this.name,
    this.avatarUrl,
    this.showEditButton = false,
    this.onEdit,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth = 0.0,
  }) : radius = 40.0;

  /// Extra large avatar (radius: 56)
  const UserAvatar.xlarge({
    super.key,
    required this.name,
    this.avatarUrl,
    this.showEditButton = false,
    this.onEdit,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth = 0.0,
  }) : radius = 56.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main avatar
        _buildAvatar(context),

        // Loading overlay
        if (isLoading) _buildLoadingOverlay(context),

        // Edit button
        if (showEditButton && onEdit != null && !isLoading)
          _buildEditButton(context),
      ],
    );
  }

  /// Build the main avatar widget
  Widget _buildAvatar(BuildContext context) {
    final effectiveBackgroundColor =
        backgroundColor ?? context.theme.colorScheme.primary;
    final effectiveTextColor = textColor ?? context.theme.colorScheme.onPrimary;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? context.theme.colorScheme.outline,
                width: borderWidth,
              )
            : null,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: effectiveBackgroundColor,
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? ClipOval(
                child: UniversalImage(
                  avatarUrl!,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  placeholder: _buildInitialsWidget(
                    context,
                    effectiveTextColor,
                  ),
                  errorBuilder: (context, error, stackTrace) =>
                      _buildInitialsWidget(context, effectiveTextColor),
                ),
              )
            : _buildInitialsWidget(context, effectiveTextColor),
      ),
    );
  }

  /// Build the initials widget
  Widget _buildInitialsWidget(BuildContext context, Color textColor) {
    final initials = _getInitials(name);
    final fontSize = _getResponsiveFontSize(context);

    return Text(
      initials,
      style: context.textTheme.titleMedium?.copyWith(
        color: textColor,
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
    );
  }

  /// Build loading overlay
  Widget _buildLoadingOverlay(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: Center(
        child: Loading.small(color: Colors.white, size: radius * 0.5),
      ),
    );
  }

  /// Build edit button overlay
  Widget _buildEditButton(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: EdgeInsets.all(radius * 0.15),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.theme.colorScheme.primary,
            border: Border.all(
              color: context.theme.colorScheme.surface,
              width: 2,
            ),
          ),
          child: Icon(
            LucideIcons.camera,
            size: radius * 0.4,
            color: context.theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  /// Get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  /// Get responsive font size based on avatar radius
  double _getResponsiveFontSize(BuildContext context) {
    final baseSize = radius * 0.6;
    return Responsive.fontSize(
      context,
      mobile: baseSize,
      tablet: baseSize * 1.1,
      desktop: baseSize * 1.2,
    );
  }
}

/// Extension for quick avatar creation from user data
extension UserAvatarExtension on Widget {
  /// Wrap this widget with a user avatar
  static UserAvatar fromUser({
    required String name,
    String? avatarUrl,
    double radius = 28.0,
    bool showEditButton = false,
    VoidCallback? onEdit,
    bool isLoading = false,
  }) {
    return UserAvatar(
      name: name,
      avatarUrl: avatarUrl,
      radius: radius,
      showEditButton: showEditButton,
      onEdit: onEdit,
      isLoading: isLoading,
    );
  }
}
