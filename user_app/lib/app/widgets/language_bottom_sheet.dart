import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:convert';
import '../translations/app_translations.dart';
import '../utils/app_spacing.dart';
import '../data/services/backend_api_service.dart';
import '../data/models/language_model.dart';
import '../utils/preference_utils.dart';
import '../utils/constants.dart';

/// Language controller - handles all language management
class LanguageController extends GetxController {
  static LanguageController get to => Get.find();

  // Reactive state
  final RxList<LanguageModel> availableLanguages = <LanguageModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString currentLanguageCode = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    // Load current language from preferences
    currentLanguageCode.value = PreferenceUtils.getString(
      SharedPreferencesKeys.language,
      'en',
    );
    // Only fetch if user is authenticated
    if (BackendApiService.to.isAuthenticated) {
      fetchAvailableLanguages();
    }
  }

  /// Fetch available languages from database
  Future<List<LanguageModel>> fetchAvailableLanguages() async {
    try {
      isLoading.value = true;

      final response = await BackendApiService.to.getResourceList(
        collectionName: 'languages',
        filter: 'is_active = true || enabled_for_users = true',
        sort: 'is_default desc, name asc',
      );

      final languages = response.items
          .map((record) => LanguageModel.fromRecord(record))
          .toList();
      availableLanguages.assignAll(languages);

      return languages;
    } catch (e) {
      debugPrint('Error fetching languages: $e');
      // Fallback to default English if database fails
      final defaultEnglish = LanguageModel(
        id: 'default_en',
        code: 'en',
        name: 'English',
        nativeName: 'English',
        isActive: true,
        isDefault: true,
        translationsUrl: '',
        translations: {},
        version: 1,
      );
      availableLanguages.assignAll([defaultEnglish]);
      return [defaultEnglish];
    } finally {
      isLoading.value = false;
    }
  }

  /// Get cached translations for a language
  Map<String, String>? getCachedTranslations(String languageCode) {
    try {
      final cachedData = PreferenceUtils.getString(
        'translations_$languageCode',
        '',
      );
      if (cachedData.isEmpty) return null;

      final Map<String, dynamic> jsonData = json.decode(cachedData);
      return Map<String, String>.from(jsonData);
    } catch (e) {
      debugPrint('Error getting cached translations: $e');
      return null;
    }
  }

  /// Cache translations locally
  Future<void> cacheTranslations(
    String languageCode,
    Map<String, String> translations,
  ) async {
    try {
      final jsonString = json.encode(translations);
      await PreferenceUtils.setString('translations_$languageCode', jsonString);

      // Also cache the version number
      final language = availableLanguages.firstWhereOrNull(
        (lang) => lang.code == languageCode,
      );
      if (language != null) {
        await PreferenceUtils.setInt(
          'translations_version_$languageCode',
          language.version.toInt(),
        );
      }
    } catch (e) {
      debugPrint('Error caching translations: $e');
    }
  }

  /// Download translations from URL or get from database
  Future<Map<String, String>?> downloadTranslations(String languageCode) async {
    try {
      final language = availableLanguages.firstWhereOrNull(
        (lang) => lang.code == languageCode,
      );
      if (language == null) return null;

      // First, check if translations are stored in database
      if (language.translations.isNotEmpty) {
        final translations = Map<String, String>.from(language.translations);
        await cacheTranslations(languageCode, translations);
        return translations;
      }

      // TODO: Implement URL download if translations_url is provided
      // For now, return empty map for non-English languages
      if (languageCode != 'en') {
        return <String, String>{};
      }

      return null;
    } catch (e) {
      debugPrint('Error downloading translations: $e');
      return null;
    }
  }

  /// Set the current language
  Future<void> setLanguage(String languageCode) async {
    try {
      // Save to preferences
      currentLanguageCode.value = languageCode;
      await PreferenceUtils.setString(
        SharedPreferencesKeys.language,
        languageCode,
      );

      // Get or download translations
      Map<String, String>? translations = getCachedTranslations(languageCode);

      translations ??= await downloadTranslations(languageCode);

      // Update GetX locale if translations are available
      if (translations != null && translations.isNotEmpty) {
        // Update the dynamic translations in AppTranslation
        await updateAppTranslations(languageCode, translations);
      }

      // Update GetX locale
      final locale = _getLocale(languageCode);
      Get.updateLocale(locale);

      HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  /// Update app translations dynamically
  Future<void> updateAppTranslations(
    String languageCode,
    Map<String, String> translations,
  ) async {
    // Update the dynamic translations in AppTranslation
    AppTranslation.updateTranslations(languageCode, translations);

    // Also cache the translations locally
    await cacheTranslations(languageCode, translations);
  }

  /// Get the current language model
  LanguageModel? get currentLanguage {
    return availableLanguages.firstWhereOrNull(
      (lang) => lang.code == currentLanguageCode.value,
    );
  }

  /// Get the default language (fallback)
  LanguageModel? get defaultLanguage {
    return availableLanguages.firstWhereOrNull((lang) => lang.isDefault);
  }

  /// Get current language display name
  String get currentLanguageDisplayName {
    final currentLang = currentLanguage;
    return currentLang?.shortDisplayName ?? 'English';
  }

  /// Check if language data needs update
  bool needsUpdate(String languageCode) {
    try {
      final language = availableLanguages.firstWhereOrNull(
        (lang) => lang.code == languageCode,
      );
      if (language == null) return true;

      final cachedVersion = PreferenceUtils.getInt(
        'translations_version_$languageCode',
        0,
      );
      return language.version.toInt() > cachedVersion;
    } catch (e) {
      return true;
    }
  }

  /// Update language data if needed
  Future<void> updateLanguageData() async {
    // Refresh available languages from database
    await fetchAvailableLanguages();

    // Check if current language needs update
    if (needsUpdate(currentLanguageCode.value)) {
      await downloadTranslations(currentLanguageCode.value);
    }
  }

  /// Convert language code to locale
  Locale _getLocale(String languageCode) => switch (languageCode) {
    'sw' => const Locale('sw', 'TZ'),
    'lg' => const Locale('lg', 'UG'),
    'fr' => const Locale('fr', 'FR'),
    'ar' => const Locale('ar', 'SA'),
    _ => const Locale('en', 'US'),
  };
}

/// Compact language selection bottom sheet
class LanguageBottomSheet extends StatelessWidget {
  const LanguageBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LanguageController>(
      init: LanguageController(),
      initState: (state) {
        // Ensure languages are fetched when bottom sheet is shown
        state.controller?.fetchAvailableLanguages();
      },
      builder: (controller) => Container(
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
            Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (controller.availableLanguages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Text('No languages available'),
                  ),
                );
              }

              return Column(
                children: controller.availableLanguages.map((language) {
                  return _buildOption(
                    context,
                    controller,
                    language.code,
                    language.name,
                    language.nativeName.isNotEmpty
                        ? language.nativeName
                        : language.name,
                    LucideIcons.languages, // Use generic language icon for all
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    LanguageController controller,
    String languageCode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Obx(() {
      final isSelected = controller.currentLanguageCode.value == languageCode;
      return ListTile(
        leading: Icon(
          icon,
          color: isSelected ? context.theme.colorScheme.primary : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? context.theme.colorScheme.primary : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: isSelected
            ? Icon(
                LucideIcons.check,
                color: context.theme.colorScheme.primary,
                size: 20,
              )
            : null,
        onTap: () async {
          await controller.setLanguage(languageCode);
          Get.back();
        },
        contentPadding: AppSpacing.listItemPadding,
      );
    });
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
