import 'package:flutter/material.dart';
import 'package:universal_image/universal_image.dart';
import '../utils/app_spacing.dart';
import '../translations/app_translations.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';

class AppLogo extends StatelessWidget {
  final double? logoSize;
  final double? shadowBlur;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final bool showTitle;
  final bool showSubtitle;
  final String? customSubtitle;

  const AppLogo({
    super.key,
    this.logoSize,
    this.shadowBlur,
    this.titleStyle,
    this.subtitleStyle,
    this.showTitle = true,
    this.showSubtitle = true,
    this.customSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveLogoSize = logoSize ?? 120.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        UniversalImage(
          'assets/logo.png',
          width: effectiveLogoSize,
          height: effectiveLogoSize,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: effectiveLogoSize,
              height: effectiveLogoSize,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'MEDI\nGUIDE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: effectiveLogoSize * 0.15,
                  ),
                ),
              ),
            );
          },
        ),
        if (showSubtitle) ...[
          AppSpacing.sm.gap,
          Text(
            customSubtitle ?? AppTranslationKey.welcomeBody.tr,
            style:
                subtitleStyle ??
                theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ],
    );
  }
}
