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

class _ProfileUnavailable extends StatelessWidget {
  const _ProfileUnavailable();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.userX, size: 48, color: colors.onSurfaceVariant),
            AppSpacing.gapMd,
            Text(
              'Profile unavailable',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AppSpacing.gapSm,
            Text(
              'Your profile information could not be loaded.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhotoSection extends StatelessWidget {
  const _ProfilePhotoSection({
    required this.name,
    required this.avatarUrl,
    required this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          Semantics(
            button: true,
            label: 'Change profile photo',
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar.xlarge(
                    name: name,
                    avatarUrl: avatarUrl,
                    showEditButton: false,
                    isLoading: false,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 3),
                      ),
                      child: Icon(
                        LucideIcons.camera,
                        size: 16,
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapSm,
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(LucideIcons.camera, size: 16),
            label: const Text('Change photo'),
          ),
        ],
      ),
    );
  }
}

class _ProfileFormSection extends StatelessWidget {
  const _ProfileFormSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: colors.primary, size: 19),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.gapMd,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) AppSpacing.gapMd,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ResponsiveFieldRow extends StatelessWidget {
  const _ResponsiveFieldRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!context.isLargerThanMobile) {
      return Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1) AppSpacing.gapMd,
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          Expanded(child: children[index]),
          if (index < children.length - 1) AppSpacing.hGapMd,
        ],
      ],
    );
  }
}

class _UnsavedChangesNotice extends StatelessWidget {
  const _UnsavedChangesNotice({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.circleDot,
            size: 18,
            color: colors.onSecondaryContainer,
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              'You have unsaved changes.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: isSaving ? null : onSave,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
