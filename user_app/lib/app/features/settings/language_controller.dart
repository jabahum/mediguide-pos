import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../data/models/language_model.dart';
import '../../providers/core_providers.dart';
import '../../translations/app_translations.dart';
import '../../utils/constants.dart';

final class LanguageState {
  const LanguageState({required this.languages, required this.currentCode});

  final List<LanguageModel> languages;
  final String currentCode;

  LanguageModel? get currentLanguage => _findLanguage(languages, currentCode);
  String get displayName => currentLanguage?.shortDisplayName ?? 'English';

  LanguageState copyWith({
    List<LanguageModel>? languages,
    String? currentCode,
  }) => LanguageState(
    languages: languages ?? this.languages,
    currentCode: currentCode ?? this.currentCode,
  );
}

final languageControllerProvider =
    AsyncNotifierProvider<LanguageController, LanguageState>(
      LanguageController.new,
    );

class LanguageController extends AsyncNotifier<LanguageState> {
  @override
  Future<LanguageState> build() async {
    final preferences = ref.watch(sharedPreferencesProvider);
    final currentCode =
        preferences.getString(SharedPreferencesKeys.language) ?? 'en';
    if (!ref.watch(backendApiServiceProvider).isAuthenticated) {
      return LanguageState(
        languages: [_defaultEnglish],
        currentCode: currentCode,
      );
    }
    try {
      final languages = await ref.watch(languageRepositoryProvider).available();
      return LanguageState(
        languages: languages.isEmpty ? [_defaultEnglish] : languages,
        currentCode: currentCode,
      );
    } catch (_) {
      return LanguageState(
        languages: [_defaultEnglish],
        currentCode: currentCode,
      );
    }
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    state = const AsyncLoading<LanguageState>().copyWithPrevious(state);
    try {
      final languages = await ref.read(languageRepositoryProvider).available();
      state = AsyncData(
        LanguageState(
          languages: languages.isEmpty ? [_defaultEnglish] : languages,
          currentCode: previous?.currentCode ?? 'en',
        ),
      );
    } catch (error, stackTrace) {
      state = previous == null
          ? AsyncError(error, stackTrace)
          : AsyncData(previous);
    }
  }

  Future<void> setLanguage(String languageCode) async {
    final current = state.valueOrNull;
    if (current == null ||
        _findLanguage(current.languages, languageCode) == null) {
      throw ArgumentError.value(
        languageCode,
        'languageCode',
        'Language is unavailable',
      );
    }

    await ref
        .read(sharedPreferencesProvider)
        .setString(SharedPreferencesKeys.language, languageCode);
    state = AsyncData(current.copyWith(currentCode: languageCode));

    var translations = _cachedTranslations(languageCode);
    translations ??= _translationsFor(languageCode, current);
    if (translations != null && translations.isNotEmpty) {
      AppTranslation.updateTranslations(languageCode, translations);
      await _cacheTranslations(languageCode, translations, current);
    }
    Get.updateLocale(_localeFor(languageCode));
    await HapticFeedback.selectionClick();
  }

  Map<String, String>? _cachedTranslations(String languageCode) {
    try {
      final raw = ref
          .read(sharedPreferencesProvider)
          .getString('translations_$languageCode');
      if (raw == null || raw.isEmpty) return null;
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Map<String, String>? _translationsFor(
    String languageCode,
    LanguageState current,
  ) {
    final language = _findLanguage(current.languages, languageCode);
    if (language == null) return null;
    if (language.translations.isNotEmpty) {
      return Map<String, String>.from(language.translations);
    }
    return languageCode == 'en' ? null : <String, String>{};
  }

  Future<void> _cacheTranslations(
    String languageCode,
    Map<String, String> translations,
    LanguageState current,
  ) async {
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setString(
      'translations_$languageCode',
      jsonEncode(translations),
    );
    final language = _findLanguage(current.languages, languageCode);
    if (language != null) {
      await preferences.setInt(
        'translations_version_$languageCode',
        language.version.toInt(),
      );
    }
  }
}

LanguageModel? _findLanguage(List<LanguageModel> languages, String code) {
  for (final language in languages) {
    if (language.code == code) return language;
  }
  return null;
}

Locale _localeFor(String code) => switch (code) {
  'sw' => const Locale('sw', 'TZ'),
  'lg' => const Locale('lg', 'UG'),
  'fr' => const Locale('fr', 'FR'),
  'ar' => const Locale('ar', 'SA'),
  _ => const Locale('en', 'US'),
};

final _defaultEnglish = LanguageModel(
  id: 'default_en',
  code: 'en',
  name: 'English',
  nativeName: 'English',
  isActive: true,
  isDefault: true,
  translationsUrl: '',
  translations: const {},
  version: 1,
);
