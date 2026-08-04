import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/app/features/settings/app_settings_controller.dart';
import 'package:user_app/app/core/di/core_providers.dart';
import 'package:user_app/app/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores and persists theme selection', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesKeys.themeMode: ThemeModes.dark,
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(appSettingsControllerProvider).materialThemeMode,
      ThemeMode.dark,
    );

    await container
        .read(appSettingsControllerProvider.notifier)
        .setThemeMode(ThemeModes.light);

    expect(
      container.read(appSettingsControllerProvider).materialThemeMode,
      ThemeMode.light,
    );
    expect(
      preferences.getString(SharedPreferencesKeys.themeMode),
      ThemeModes.light,
    );
  });

  test('rejects unsupported theme values', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(
      () => container
          .read(appSettingsControllerProvider.notifier)
          .setThemeMode('sepia'),
      throwsArgumentError,
    );
  });
}
