import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../features/settings/language_controller.dart';
import '../translations/app_translations.dart';
import '../utils/app_spacing.dart';

class LanguageBottomSheet extends ConsumerWidget {
  const LanguageBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languages = ref.watch(languageControllerProvider);
    return Container(
      padding: AppSpacing.paddingLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: context.theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppTranslationKey.chooseLanguage.tr,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AppSpacing.gapMd,
          languages.when(
            loading: () => Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: const CircularProgressIndicator(),
              ),
            ),
            error: (error, stackTrace) => Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Unable to load languages'),
                    TextButton(
                      onPressed: () => ref
                          .read(languageControllerProvider.notifier)
                          .refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (state) => state.languages.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: const Text('No languages available'),
                    ),
                  )
                : Column(
                    children: state.languages
                        .map(
                          (language) => _LanguageOption(
                            languageCode: language.code,
                            title: language.name,
                            subtitle: language.nativeName.isNotEmpty
                                ? language.nativeName
                                : language.name,
                            selected: state.currentCode == language.code,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  static void show() {
    Get.bottomSheet(
      const LanguageBottomSheet(),
      backgroundColor: Get.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      isScrollControlled: false,
      enableDrag: true,
      isDismissible: true,
    );
  }
}

class _LanguageOption extends ConsumerWidget {
  const _LanguageOption({
    required this.languageCode,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final String languageCode;
  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    leading: Icon(
      LucideIcons.languages,
      color: selected ? context.theme.colorScheme.primary : null,
    ),
    title: Text(
      title,
      style: TextStyle(
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? context.theme.colorScheme.primary : null,
      ),
    ),
    subtitle: Text(subtitle),
    trailing: selected
        ? Icon(
            LucideIcons.check,
            color: context.theme.colorScheme.primary,
            size: 20,
          )
        : null,
    onTap: () async {
      await ref
          .read(languageControllerProvider.notifier)
          .setLanguage(languageCode);
      Get.back();
    },
    contentPadding: AppSpacing.listItemPadding,
  );
}
