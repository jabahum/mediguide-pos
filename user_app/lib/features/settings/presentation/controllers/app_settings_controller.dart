import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/constants/app_constants.dart';

part 'app_settings_controller.g.dart';

final class AppSettingsState {
  const AppSettingsState({required this.themeMode});

  final String themeMode;

  ThemeMode get materialThemeMode => switch (themeMode) {
    ThemeModes.light => ThemeMode.light,
    ThemeModes.dark => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  AppSettingsState copyWith({String? themeMode}) {
    return AppSettingsState(themeMode: themeMode ?? this.themeMode);
  }
}

@Riverpod(keepAlive: true)
class AppSettingsController extends _$AppSettingsController {
  @override
  AppSettingsState build() {
    final preferences = ref.watch(sharedPreferencesProvider);

    return AppSettingsState(
      themeMode:
          preferences.getString(SharedPreferencesKeys.themeMode) ??
          ThemeModes.system,
    );
  }

  Future<void> setThemeMode(String mode) async {
    if (!ThemeModes.values.contains(mode)) {
      throw ArgumentError.value(mode, 'mode', 'Unsupported theme mode');
    }

    if (state.themeMode == mode) {
      return;
    }

    state = state.copyWith(themeMode: mode);

    await ref
        .read(sharedPreferencesProvider)
        .setString(SharedPreferencesKeys.themeMode, mode);

    await HapticFeedback.selectionClick();
  }

  Future<void> resetThemeMode() {
    return setThemeMode(ThemeModes.system);
  }
}
