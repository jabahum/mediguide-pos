import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';

/// Reusable HTML styles for consistent content rendering across the app
class HtmlStyles {
  HtmlStyles._();

  /// Standard content HTML styles for guidelines and other content
  static Map<String, Style> content(BuildContext context) => {
    "body": Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      fontSize: FontSize(context.textTheme.bodyMedium?.fontSize ?? 14),
      color: context.theme.colorScheme.onSurface,
      fontFamily: context.textTheme.bodyMedium?.fontFamily,
    ),
    "h1, h2, h3, h4, h5, h6": Style(
      margin: Margins.only(top: 16, bottom: 8),
      fontWeight: FontWeight.w600,
      color: context.theme.colorScheme.onSurface,
    ),
    "p": Style(
      margin: Margins.only(bottom: 12),
      lineHeight: const LineHeight(1.5),
    ),
    "ul, ol": Style(
      margin: Margins.only(bottom: 12),
      padding: HtmlPaddings.only(left: 20),
    ),
    "li": Style(margin: Margins.only(bottom: 4)),
    "strong, b": Style(fontWeight: FontWeight.w600),
    "em, i": Style(fontStyle: FontStyle.italic),
    "blockquote": Style(
      margin: Margins.only(left: 16, top: 8, bottom: 8),
      padding: HtmlPaddings.only(left: 16, top: 8, bottom: 8),
      border: Border(
        left: BorderSide(color: context.theme.colorScheme.primary, width: 4),
      ),
      backgroundColor: context.theme.colorScheme.surfaceContainer,
    ),
    "code": Style(
      backgroundColor: context.theme.colorScheme.surfaceContainer,
      color: context.theme.colorScheme.onSurfaceVariant,
      padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
      fontSize: FontSize.smaller,
      fontFamily: 'monospace',
    ),
    "pre": Style(
      backgroundColor: context.theme.colorScheme.surfaceContainer,
      padding: HtmlPaddings.all(12),
      margin: Margins.only(bottom: 12),
      fontSize: FontSize.smaller,
      fontFamily: 'monospace',
    ),
    "table": Style(margin: Margins.only(bottom: 12)),
    "th": Style(
      backgroundColor: context.theme.colorScheme.surfaceContainer,
      padding: HtmlPaddings.all(8),
      fontWeight: FontWeight.w600,
    ),
    "td": Style(
      padding: HtmlPaddings.all(8),
      border: Border.all(
        color: context.theme.colorScheme.outline.withValues(alpha: 0.2),
      ),
    ),
  };

  /// Compact HTML styles for smaller content areas
  static Map<String, Style> compact(BuildContext context) => {
    "body": Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      fontSize: FontSize(context.textTheme.bodySmall?.fontSize ?? 12),
      color: context.theme.colorScheme.onSurface,
      fontFamily: context.textTheme.bodySmall?.fontFamily,
    ),
    "h1, h2, h3, h4, h5, h6": Style(
      margin: Margins.only(top: 8, bottom: 4),
      fontWeight: FontWeight.w600,
      fontSize: FontSize.medium,
    ),
    "p": Style(
      margin: Margins.only(bottom: 6),
      lineHeight: const LineHeight(1.4),
    ),
    "ul, ol": Style(
      margin: Margins.only(bottom: 6),
      padding: HtmlPaddings.only(left: 16),
    ),
    "li": Style(margin: Margins.only(bottom: 2)),
    "strong, b": Style(fontWeight: FontWeight.w600),
    "em, i": Style(fontStyle: FontStyle.italic),
  };

  /// Large HTML styles for prominent content
  static Map<String, Style> large(BuildContext context) => {
    "body": Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      fontSize: FontSize(context.textTheme.bodyLarge?.fontSize ?? 16),
      color: context.theme.colorScheme.onSurface,
      fontFamily: context.textTheme.bodyLarge?.fontFamily,
    ),
    "h1, h2, h3, h4, h5, h6": Style(
      margin: Margins.only(top: 20, bottom: 12),
      fontWeight: FontWeight.w700,
      color: context.theme.colorScheme.onSurface,
    ),
    "p": Style(
      margin: Margins.only(bottom: 16),
      lineHeight: const LineHeight(1.6),
    ),
    "ul, ol": Style(
      margin: Margins.only(bottom: 16),
      padding: HtmlPaddings.only(left: 24),
    ),
    "li": Style(margin: Margins.only(bottom: 6)),
    "strong, b": Style(fontWeight: FontWeight.w700),
    "em, i": Style(fontStyle: FontStyle.italic),
  };
}
