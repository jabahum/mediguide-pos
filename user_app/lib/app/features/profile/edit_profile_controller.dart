import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../features/auth/auth_controller.dart';
import '../../providers/core_providers.dart';

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
  }) => EditProfileState(
    hasChanges: hasChanges ?? this.hasChanges,
    isSaving: isSaving ?? this.isSaving,
    error: clearError ? null : error ?? this.error,
  );
}

final editProfileControllerProvider =
    AutoDisposeNotifierProvider<EditProfileController, EditProfileState>(
      EditProfileController.new,
    );

class EditProfileController extends AutoDisposeNotifier<EditProfileState> {
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
  EditProfileState build() => const EditProfileState();

  void setHasChanges(bool value) {
    if (state.hasChanges == value) return;
    state = state.copyWith(hasChanges: value, clearError: true);
  }

  Future<bool> save(Map<String, dynamic> formValues) async {
    if (state.isSaving) return false;
    if (!state.hasChanges) return true;

    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user == null) throw StateError('Authenticated user is unavailable');

    final update = <String, dynamic>{};
    for (final field in editableFields) {
      final value = formValues[field]?.toString().trim();
      if (value != null && value.isNotEmpty) update[field] = value;
    }
    if (user.preferredLanguage != null) {
      update['preferredLanguage'] = user.preferredLanguage!.name;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final record = await ref
          .read(userRepositoryProvider)
          .updateProfile(user.id, update);
      final updatedUser = User.fromRecord(record);
      await ref.read(authControllerProvider.notifier).replaceUser(updatedUser);
      state = const EditProfileState();
      return true;
    } catch (error) {
      state = state.copyWith(isSaving: false, error: error);
      rethrow;
    }
  }
}
