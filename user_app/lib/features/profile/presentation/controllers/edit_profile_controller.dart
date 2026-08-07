import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';

part 'edit_profile_controller.g.dart';

final class EditProfileState {
  const EditProfileState({
    this.hasChanges = false,
    this.isSaving = false,
    this.error,
  });

  final bool hasChanges;
  final bool isSaving;
  final Object? error;

  EditProfileState copyWith({
    bool? hasChanges,
    bool? isSaving,
    Object? error,
    bool clearError = false,
  }) {
    return EditProfileState(
      hasChanges: hasChanges ?? this.hasChanges,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
    );
  }
}

@riverpod
class EditProfileController extends _$EditProfileController {
  static const editableFields = <String>{
    'name',
    'phone',
    'alternativePhone',
    'address',
    'city',
    'state',
    'country',
    'postalCode',
    'organization',
    'department',
    'jobTitle',
    'specialization',
  };

  @override
  EditProfileState build() {
    return const EditProfileState();
  }

  // ======================================================
  // DIRTY STATE
  // ======================================================

  void setHasChanges(bool value) {
    if (state.hasChanges == value) {
      return;
    }

    state = state.copyWith(hasChanges: value, clearError: true);
  }

  // ======================================================
  // SAVE PROFILE
  // ======================================================

  Future<bool> save(Map<String, dynamic> formValues) async {
    if (state.isSaving) {
      return false;
    }

    if (!state.hasChanges) {
      return true;
    }

    final user = ref.read(authControllerProvider).valueOrNull?.user;

    if (user == null) {
      throw StateError('Authenticated user is unavailable');
    }

    final update = <String, dynamic>{};

    for (final field in editableFields) {
      final value = formValues[field]?.toString().trim();

      if (value != null && value.isNotEmpty) {
        update[field] = value;
      }
    }

    if (user.preferredLanguage != null) {
      update['preferredLanguage'] = user.preferredLanguage!.name;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final updatedUser = await ref
          .read(userRepositoryProvider)
          .updateProfile(user.id, update);

      await ref.read(authControllerProvider.notifier).replaceUser(updatedUser);

      state = const EditProfileState();

      return true;
    } catch (error) {
      state = state.copyWith(isSaving: false, error: error);

      rethrow;
    }
  }

  // ======================================================
  // RESET
  // ======================================================

  void reset() {
    state = const EditProfileState();
  }
}
