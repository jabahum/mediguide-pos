import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/core/utils/loading.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/profile/presentation/controllers/edit_profile_controller.dart';
import 'package:user_app/shared/widgets/user_avatar.dart';
import 'package:user_app/core/utils/responsive.dart';

part '../widgets/edit_profile_page_profile_unavailable.dart';
part '../widgets/edit_profile_page_profile_photo_section.dart';
part '../widgets/edit_profile_page_profile_form_section.dart';
part '../widgets/edit_profile_page_responsive_field_row.dart';
part '../widgets/edit_profile_page_unsaved_changes_notice.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormBuilderState>();

  static const _fieldNames = <String>[
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
  ];

  // =========================================================================
  // NAVIGATION
  // =========================================================================

  Future<void> _close() async {
    final state = ref.read(editProfileControllerProvider);

    if (!state.hasChanges) {
      AppNavigator.pop();
      return;
    }

    final discard = await AppNavigator.dialog<bool>(
      child: AlertDialog(
        icon: const Icon(LucideIcons.triangleAlert),
        title: Text(AppTranslationKey.discardChanges.tr),
        content: Text(AppTranslationKey.discardChangesConfirmation.tr),
        actions: [
          TextButton(
            onPressed: () => AppNavigator.pop(false),
            child: Text(AppTranslationKey.cancel.tr),
          ),
          FilledButton.tonal(
            onPressed: () => AppNavigator.pop(true),
            child: Text(AppTranslationKey.discard.tr),
          ),
        ],
      ),
    );

    if (discard == true && mounted) {
      AppNavigator.pop();
    }
  }

  // =========================================================================
  // SAVE
  // =========================================================================

  Future<void> _saveProfile() async {
    final form = _formKey.currentState;

    if (form == null) return;

    final valid = form.saveAndValidate();

    if (!valid) {
      _showValidationMessage();
      return;
    }

    final editState = ref.read(editProfileControllerProvider);

    if (!editState.hasChanges || editState.isSaving) {
      return;
    }

    try {
      final values = _normalizedFormValues(form.value);

      final saved = await ref
          .read(editProfileControllerProvider.notifier)
          .save(values);

      if (!saved || !mounted) return;

      final messageContext = AppKeys.navigatorKey.currentContext;

      if (messageContext != null && messageContext.mounted) {
        AppMessage.success(
          messageContext,
          AppTranslationKey.profileUpdatedSuccessfully.tr,
        );
      }

      // Return true to ProfilePage so it knows something changed.
      AppNavigator.pop(true);
    } catch (_) {
      if (!mounted) return;

      final messageContext = AppKeys.navigatorKey.currentContext;

      if (messageContext != null && messageContext.mounted) {
        AppMessage.error(
          messageContext,
          AppTranslationKey.failedToUpdateProfile.tr,
        );
      }
    }
  }

  void _showValidationMessage() {
    final messageContext = AppKeys.navigatorKey.currentContext;

    if (messageContext == null) return;

    AppMessage.error(messageContext, 'Please review the highlighted fields.');
  }

  // =========================================================================
  // CHANGE DETECTION
  // =========================================================================

  void _updateHasChanges(dynamic user) {
    if (user == null) return;

    final form = _formKey.currentState;

    if (form == null) return;

    final values = _normalizedFormValues(form.instantValue);

    final original = <String, dynamic>{
      'name': _normalize(user.name),
      'phone': _normalize(user.phone),
      'alternativePhone': _normalize(user.alternativePhone),
      'address': _normalize(user.address),
      'city': _normalize(user.city),
      'state': _normalize(user.state),
      'country': _normalize(user.country),
      'postalCode': _normalize(user.postalCode),
      'organization': _normalize(user.organization),
      'department': _normalize(user.department),
      'jobTitle': _normalize(user.jobTitle),
      'specialization': _normalize(user.specialization),
    };

    var hasChanges = false;

    for (final field in _fieldNames) {
      if (_normalize(values[field]) != _normalize(original[field])) {
        hasChanges = true;
        break;
      }
    }

    final current = ref.read(editProfileControllerProvider);

    if (current.hasChanges != hasChanges) {
      ref
          .read(editProfileControllerProvider.notifier)
          .setHasChanges(hasChanges);
    }
  }

  Map<String, dynamic> _normalizedFormValues(Map<String, dynamic> values) {
    return {
      for (final entry in values.entries) entry.key: _normalize(entry.value),
    };
  }

  String _normalize(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final editState = ref.watch(editProfileControllerProvider);

    final user = ref.watch(
      authControllerProvider.select((value) => value.valueOrNull?.user),
    );

    final avatarUrl = user?.avatar.isNotEmpty == true
        ? ref.read(backendApiServiceProvider).getFileUrl(filename: user!.avatar)
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _close();
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,

        // ===================================================================
        // APP BAR
        // ===================================================================
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: editState.isSaving ? null : _close,
            icon: const Icon(LucideIcons.arrowLeft),
          ),
          title: const Text('Edit Profile'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: TextButton(
                onPressed: editState.isSaving || !editState.hasChanges
                    ? null
                    : _saveProfile,
                child: editState.isSaving
                    ? SizedBox(width: 20, height: 20, child: Loading.small())
                    : Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: editState.hasChanges
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
          ],
        ),

        // ===================================================================
        // BODY
        // ===================================================================
        body: user == null
            ? const _ProfileUnavailable()
            : FormBuilder(
                key: _formKey,
                initialValue: {
                  'name': user.name,
                  'phone': user.phone,
                  'alternativePhone': user.alternativePhone,
                  'address': user.address,
                  'city': user.city,
                  'state': user.state,
                  'country': user.country,
                  'postalCode': user.postalCode,
                  'organization': user.organization,
                  'department': user.department,
                  'jobTitle': user.jobTitle,
                  'specialization': user.specialization,
                },
                onChanged: () => _updateHasChanges(user),
                child: SafeArea(
                  top: false,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      context.responsiveHorizontalPadding,
                      AppSpacing.lg,
                      context.responsiveHorizontalPadding,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      // =====================================================
                      // PROFILE PHOTO
                      // =====================================================
                      _ProfilePhotoSection(
                        name: user.name,
                        avatarUrl: avatarUrl,
                        onTap: _showAvatarUnsupported,
                      ),

                      AppSpacing.gapXl,

                      // =====================================================
                      // PERSONAL INFORMATION
                      // =====================================================
                      _ProfileFormSection(
                        icon: LucideIcons.user,
                        title: 'Personal information',
                        description:
                            'Basic information used across your MediGuide profile.',
                        children: [
                          _textField(
                            name: 'name',
                            label: '${AppTranslationKey.fullName.tr} *',
                            hint: 'Enter your full name',
                            icon: LucideIcons.user,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                errorText: AppTranslationKey.nameRequired.tr,
                              ),
                              FormBuilderValidators.minLength(
                                2,
                                errorText: 'Name must be at least 2 characters',
                              ),
                            ]),
                          ),

                          _textField(
                            name: 'phone',
                            label: AppTranslationKey.phoneNumber.tr,
                            hint: '+256 700 000000',
                            icon: LucideIcons.phone,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            validator: _optionalPhoneValidator(
                              AppTranslationKey.invalidPhoneFormat.tr,
                            ),
                          ),

                          _textField(
                            name: 'alternativePhone',
                            label: 'Alternative phone',
                            hint: '+256 700 000000',
                            icon: LucideIcons.phoneCall,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: _optionalPhoneValidator(
                              AppTranslationKey
                                  .invalidAlternativePhoneFormat
                                  .tr,
                            ),
                          ),
                        ],
                      ),

                      AppSpacing.gapXl,

                      // =====================================================
                      // ADDRESS
                      // =====================================================
                      _ProfileFormSection(
                        icon: LucideIcons.mapPin,
                        title: 'Address information',
                        description:
                            'Optional contact and location information.',
                        children: [
                          _textField(
                            name: 'address',
                            label: 'Address',
                            hint: 'Street or physical address',
                            icon: LucideIcons.mapPin,
                            textInputAction: TextInputAction.next,
                          ),

                          _ResponsiveFieldRow(
                            children: [
                              _textField(
                                name: 'city',
                                label: 'City',
                                hint: 'Kampala',
                                icon: LucideIcons.building,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                              ),
                              _textField(
                                name: 'state',
                                label: 'Region / Province',
                                hint: 'Central',
                                icon: LucideIcons.map,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                              ),
                            ],
                          ),

                          _ResponsiveFieldRow(
                            children: [
                              _textField(
                                name: 'country',
                                label: 'Country',
                                hint: 'Uganda',
                                icon: LucideIcons.globe,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                              ),
                              _textField(
                                name: 'postalCode',
                                label: 'Postal code',
                                hint: 'Optional',
                                icon: LucideIcons.mailbox,
                                textInputAction: TextInputAction.next,
                              ),
                            ],
                          ),
                        ],
                      ),

                      AppSpacing.gapXl,

                      // =====================================================
                      // PROFESSIONAL INFORMATION
                      // =====================================================
                      _ProfileFormSection(
                        icon: LucideIcons.briefcaseMedical,
                        title: AppTranslationKey.professionalInfo.tr,
                        description:
                            'Your professional context helps personalize clinical content.',
                        children: [
                          _textField(
                            name: 'organization',
                            label: 'Organization',
                            hint: 'Ministry of Health',
                            icon: LucideIcons.building2,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                          ),

                          _ResponsiveFieldRow(
                            children: [
                              _textField(
                                name: 'department',
                                label: 'Department',
                                hint: 'Emergency Medicine',
                                icon: LucideIcons.building,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                              ),
                              _textField(
                                name: 'jobTitle',
                                label: 'Job title',
                                hint: 'Clinical Officer',
                                icon: LucideIcons.badgeCheck,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                              ),
                            ],
                          ),

                          _textField(
                            name: 'specialization',
                            label: 'Specialization',
                            hint: 'General Practice',
                            icon: LucideIcons.stethoscope,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                      ),

                      if (editState.hasChanges) ...[
                        AppSpacing.gapLg,
                        _UnsavedChangesNotice(
                          isSaving: editState.isSaving,
                          onSave: _saveProfile,
                        ),
                      ],

                      AppSpacing.gapXl,
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _textField({
    required String name,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Iterable<String>? autofillHints,
  }) {
    return FormBuilderTextField(
      name: name,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }

  String? Function(String?) _optionalPhoneValidator(String errorMessage) {
    return (value) {
      final normalized = value?.trim() ?? '';

      if (normalized.isEmpty) return null;

      final valid = RegExp(r'^\+?[0-9\s\-\(\)]{7,20}$').hasMatch(normalized);

      return valid ? null : errorMessage;
    };
  }

  void _showAvatarUnsupported() {
    final messageContext = AppKeys.navigatorKey.currentContext;

    if (messageContext == null) return;

    AppMessage.info(
      messageContext,
      'Profile photo updates are not available yet.',
    );
  }
}
