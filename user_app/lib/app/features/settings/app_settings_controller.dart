import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/core_providers.dart';
import '../../utils/constants.dart';

final class AppSettingsState {
  const AppSettingsState({required this.themeMode});

  final String themeMode;

  ThemeMode get materialThemeMode => switch (themeMode) {
    ThemeModes.light => ThemeMode.light,
    ThemeModes.dark => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  AppSettingsState copyWith({String? themeMode}) =>
      AppSettingsState(themeMode: themeMode ?? this.themeMode);
}

final appSettingsControllerProvider =
    NotifierProvider<AppSettingsController, AppSettingsState>(
      AppSettingsController.new,
    );

class AppSettingsController extends Notifier<AppSettingsState> {
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
    if (mode != ThemeModes.light &&
        mode != ThemeModes.dark &&
        mode != ThemeModes.system) {
      throw ArgumentError.value(mode, 'mode', 'Unsupported theme mode');
    }
    if (state.themeMode == mode) return;

    state = state.copyWith(themeMode: mode);
    await ref
        .read(sharedPreferencesProvider)
        .setString(SharedPreferencesKeys.themeMode, mode);
    await HapticFeedback.selectionClick();
  }
}
