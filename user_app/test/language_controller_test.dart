import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/app/data/services/backend_api_service.dart';
import 'package:user_app/app/features/settings/language_controller.dart';
import 'package:user_app/app/providers/core_providers.dart';
import 'package:user_app/app/utils/constants.dart';

final class OfflineLanguageApi extends BackendApiService {
  @override
  bool get isAuthenticated => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores language preference with offline English fallback', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesKeys.language: 'en',
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        backendApiServiceProvider.overrideWithValue(OfflineLanguageApi()),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(languageControllerProvider.future);

    expect(state.currentCode, 'en');
    expect(state.displayName, 'English');
    expect(state.languages, hasLength(1));
  });

  test('rejects a language that is not available', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        backendApiServiceProvider.overrideWithValue(OfflineLanguageApi()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(languageControllerProvider.future);

    expect(
      () => container
          .read(languageControllerProvider.notifier)
          .setLanguage('unknown'),
      throwsArgumentError,
    );
  });
}
