import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/features/content/data/models/language_model.dart';
import 'package:user_app/l10n/app_translations.dart';

part 'language_controller.g.dart';

final class LanguageState {
  const LanguageState({required this.languages, required this.currentCode});

  final List<LanguageModel> languages;
  final String currentCode;

  LanguageModel? get currentLanguage => _findLanguage(languages, currentCode);

  String get displayName => currentLanguage?.shortDisplayName ?? 'English';

  LanguageState copyWith({
    List<LanguageModel>? languages,
    String? currentCode,
  }) {
    return LanguageState(
      languages: languages ?? this.languages,
      currentCode: currentCode ?? this.currentCode,
    );
  }
}

@Riverpod(keepAlive: true)
class LanguageController extends _$LanguageController {
  @override
  Future<LanguageState> build() async {
    final preferences = ref.watch(sharedPreferencesProvider);

    final currentCode =
        preferences.getString(SharedPreferencesKeys.language) ?? 'en';

    final api = ref.watch(backendApiServiceProvider);

    if (!api.isAuthenticated) {
      return LanguageState(
        languages: const [_defaultEnglish],
        currentCode: currentCode,
      );
    }

    try {
      final languages = await ref.watch(languageRepositoryProvider).available();

      return LanguageState(
        languages: languages.isEmpty
            ? const [_defaultEnglish]
            : List<LanguageModel>.unmodifiable(languages),
        currentCode: _resolveCurrentCode(languages, currentCode),
      );
    } catch (_) {
      return LanguageState(
        languages: const [_defaultEnglish],
        currentCode: currentCode,
      );
    }
  }

  // ======================================================
  // REFRESH
  // ======================================================

  Future<void> refresh() async {
    final previous = state.valueOrNull;

    state = const AsyncLoading<LanguageState>().copyWithPrevious(state);

    try {
      final languages = await ref.read(languageRepositoryProvider).available();

      final available = languages.isEmpty
          ? const <LanguageModel>[_defaultEnglish]
          : List<LanguageModel>.unmodifiable(languages);

      final currentCode = _resolveCurrentCode(
        available,
        previous?.currentCode ?? 'en',
      );

      state = AsyncData(
        LanguageState(languages: available, currentCode: currentCode),
      );
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
        return;
      }

      state = AsyncError(error, stackTrace);
    }
  }

  // ======================================================
  // CHANGE LANGUAGE
  // ======================================================

  Future<void> setLanguage(String languageCode) async {
    final current = state.valueOrNull;

    if (current == null) {
      throw StateError('Language settings are unavailable');
    }

    final language = _findLanguage(current.languages, languageCode);

    if (language == null) {
      throw ArgumentError.value(
        languageCode,
        'languageCode',
        'Language is unavailable',
      );
    }

    if (current.currentCode == languageCode) {
      return;
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

    AppTranslation.setLocale(_localeFor(languageCode));

    await HapticFeedback.selectionClick();
  }

  // ======================================================
  // TRANSLATION CACHE
  // ======================================================

  Map<String, String>? _cachedTranslations(String languageCode) {
    try {
      final raw = ref
          .read(sharedPreferencesProvider)
          .getString(_translationKey(languageCode));

      if (raw == null || raw.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return null;
      }

      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, String>? _translationsFor(
    String languageCode,
    LanguageState current,
  ) {
    final language = _findLanguage(current.languages, languageCode);

    if (language == null) {
      return null;
    }

    if (language.translations.isNotEmpty) {
      return Map<String, String>.from(language.translations);
    }

    // English falls back to bundled app translations.
    if (languageCode == 'en') {
      return null;
    }

    return <String, String>{};
  }

  Future<void> _cacheTranslations(
    String languageCode,
    Map<String, String> translations,
    LanguageState current,
  ) async {
    final preferences = ref.read(sharedPreferencesProvider);

    await preferences.setString(
      _translationKey(languageCode),
      jsonEncode(translations),
    );

    final language = _findLanguage(current.languages, languageCode);

    if (language == null) {
      return;
    }

    await preferences.setInt(
      _translationVersionKey(languageCode),
      language.version.toInt(),
    );
  }

  // ======================================================
  // CACHE KEYS
  // ======================================================

  String _translationKey(String languageCode) {
    return 'translations_$languageCode';
  }

  String _translationVersionKey(String languageCode) {
    return 'translations_version_$languageCode';
  }

  // ======================================================
  // HELPERS
  // ======================================================

  String _resolveCurrentCode(
    List<LanguageModel> languages,
    String currentCode,
  ) {
    if (_findLanguage(languages, currentCode) != null) {
      return currentCode;
    }

    final defaultLanguage = languages
        .where((language) => language.isDefault)
        .firstOrNull;

    return defaultLanguage?.code ?? 'en';
  }
}

LanguageModel? _findLanguage(List<LanguageModel> languages, String code) {
  for (final language in languages) {
    if (language.code == code) {
      return language;
    }
  }

  return null;
}

Locale _localeFor(String code) {
  return switch (code) {
    'sw' => const Locale('sw', 'TZ'),
    'lg' => const Locale('lg', 'UG'),
    'fr' => const Locale('fr', 'FR'),
    'ar' => const Locale('ar', 'SA'),
    _ => const Locale('en', 'US'),
  };
}

const _defaultEnglish = LanguageModel(
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
