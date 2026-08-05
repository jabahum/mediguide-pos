import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/profile/presentation/controllers/edit_profile_controller.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/loading.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/shared/widgets/user_avatar.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({super.key});

  static Future<bool?> show() async {
    return await AppNavigator.dialog<bool>(
      EditProfileDialog(),
      barrierDismissible: false,
    );
  }

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _close() async {
    final hasChanges = ref.read(editProfileControllerProvider).hasChanges;
    if (!hasChanges) {
      AppNavigator.pop();
      return;
    }
    final discard = await AppNavigator.dialog<bool>(
      AlertDialog(
        title: Text(AppTranslationKey.discardChanges.tr),
        content: Text(AppTranslationKey.discardChangesConfirmation.tr),
        actions: [
          TextButton(
            onPressed: () => AppNavigator.pop(result: false),
            child: Text(AppTranslationKey.cancel.tr),
          ),
          TextButton(
            onPressed: () => AppNavigator.pop(result: true),
            child: Text(AppTranslationKey.discard.tr),
          ),
        ],
      ),
    );
    if (discard == true) AppNavigator.pop();
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    if (!ref.read(editProfileControllerProvider).hasChanges) {
      AppNavigator.pop();
      return;
    }
    try {
      final saved = await ref
          .read(editProfileControllerProvider.notifier)
          .save(_formKey.currentState!.value);
      if (!saved || !mounted) return;
      Common.quickToast(
        type: ToastificationType.success,
        title: AppTranslationKey.profileUpdated.tr,
        description: AppTranslationKey.profileUpdatedSuccessfully.tr,
      );
      AppNavigator.pop(result: true);
    } catch (_) {
      if (!mounted) return;
      Common.quickToast(
        type: ToastificationType.error,
        title: AppTranslationKey.error.tr,
        description: AppTranslationKey.failedToUpdateProfile.tr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        if (!didPop) await _close();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppTranslationKey.editProfile.tr),
          leading: IconButton(icon: Icon(LucideIcons.x), onPressed: _close),
          actions: [
            TextButton(
              onPressed: editState.isSaving ? null : _saveProfile,
              child: editState.isSaving
                  ? SizedBox(width: 20, height: 20, child: Loading.small())
                  : Text(
                      AppTranslationKey.done.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: editState.hasChanges
                            ? context.theme.colorScheme.primary
                            : context.theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                      ),
                    ),
            ),
          ],
        ),
        body: FormBuilder(
          key: _formKey,
          initialValue: user == null
              ? {}
              : {
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
          onChanged: () {
            if (user == null) return;

            final formValues = _formKey.currentState?.instantValue;
            if (formValues == null) return;

            final hasFormChanges =
                formValues['name'] != user.name ||
                formValues['phone'] != user.phone ||
                formValues['alternativePhone'] != user.alternativePhone ||
                formValues['address'] != user.address ||
                formValues['city'] != user.city ||
                formValues['state'] != user.state ||
                formValues['country'] != user.country ||
                formValues['postalCode'] != user.postalCode ||
                formValues['organization'] != user.organization ||
                formValues['department'] != user.department ||
                formValues['jobTitle'] != user.jobTitle ||
                formValues['specialization'] != user.specialization;

            ref
                .read(editProfileControllerProvider.notifier)
                .setHasChanges(hasFormChanges);
          },
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsiveHorizontalPadding,
              vertical: context.responsiveVerticalPadding,
            ),
            children: [
              // Avatar Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        debugPrint('Avatar tapped'); // Debug
                        _showAvatarUnsupported();
                      },
                      child: UserAvatar.xlarge(
                        name: user?.name ?? AppTranslationKey.user.tr,
                        avatarUrl: avatarUrl,
                        showEditButton: true,
                        isLoading: false,
                        onEdit: () {
                          _showAvatarUnsupported();
                        },
                      ),
                    ),
                    AppSpacing.gapSm,
                    GestureDetector(
                      onTap: () {
                        debugPrint('Text tapped'); // Debug
                        _showAvatarUnsupported();
                      },
                      child: Text(
                        'Tap to change photo',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.gapXl,

              // Basic Information Section
              Row(
                children: [
                  Icon(
                    LucideIcons.user,
                    size: Responsive.iconSize(
                      context,
                      mobile: 20,
                      tablet: 22,
                      desktop: 24,
                    ),
                    color: context.theme.colorScheme.primary,
                  ),
                  AppSpacing.gapSm,
                  Text(
                    AppTranslationKey.accountSettings.tr,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapMd,

              // Name Field
              FormBuilderTextField(
                name: 'name',
                decoration: InputDecoration(
                  labelText: '${AppTranslationKey.fullName.tr} *',
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(LucideIcons.user),
                ),
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

              AppSpacing.gapMd,

              // Phone Field
              FormBuilderTextField(
                name: 'phone',
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: AppTranslationKey.phoneNumber.tr,
                  hintText: '+256 123 456 789',
                  prefixIcon: Icon(LucideIcons.phone),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.match(
                    RegExp(r'^[+]?[0-9\s\-\(\)]{7,20}$'),
                    errorText: AppTranslationKey.invalidPhoneFormat.tr,
                  ),
                ]),
              ),

              AppSpacing.gapMd,

              // Alternative Phone Field
              FormBuilderTextField(
                name: 'alternativePhone',
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Alternative Phone (Optional)',
                  hintText: '+256 987 654 321',
                  prefixIcon: Icon(LucideIcons.phone),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.match(
                    RegExp(r'^[+]?[0-9\s\-\(\)]{7,20}$'),
                    errorText:
                        AppTranslationKey.invalidAlternativePhoneFormat.tr,
                  ),
                ]),
              ),

              AppSpacing.gapXl,

              // Address Information Section
              Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: Responsive.iconSize(
                      context,
                      mobile: 20,
                      tablet: 22,
                      desktop: 24,
                    ),
                    color: context.theme.colorScheme.primary,
                  ),
                  AppSpacing.gapSm,
                  Text(
                    'Address Information',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapMd,

              FormBuilderTextField(
                name: 'address',
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'Street address',
                  prefixIcon: Icon(LucideIcons.mapPin),
                ),
              ),

              AppSpacing.gapMd,

              // City, State, Country Row
              if (context.isLargerThanMobile) ...[
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'city',
                        decoration: InputDecoration(
                          labelText: 'City',
                          hintText: 'Kampala',
                          prefixIcon: Icon(LucideIcons.building),
                        ),
                      ),
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'state',
                        decoration: InputDecoration(
                          labelText: 'State/Province',
                          hintText: 'Central',
                          prefixIcon: Icon(LucideIcons.building2),
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'country',
                        decoration: InputDecoration(
                          labelText: 'Country',
                          hintText: 'Uganda',
                          prefixIcon: Icon(LucideIcons.globe),
                        ),
                      ),
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'postalCode',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Postal Code',
                          hintText: '12345',
                          prefixIcon: Icon(LucideIcons.mailbox),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.numeric(
                            errorText: 'Please enter a valid postal code',
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                FormBuilderTextField(
                  name: 'city',
                  decoration: InputDecoration(
                    labelText: 'City',
                    hintText: 'Kampala',
                    prefixIcon: Icon(LucideIcons.building),
                  ),
                ),
                AppSpacing.gapMd,
                FormBuilderTextField(
                  name: 'state',
                  decoration: InputDecoration(
                    labelText: 'State/Province',
                    hintText: 'Central',
                    prefixIcon: Icon(LucideIcons.building2),
                  ),
                ),
                AppSpacing.gapMd,
                FormBuilderTextField(
                  name: 'country',
                  decoration: InputDecoration(
                    labelText: 'Country',
                    hintText: 'Uganda',
                    prefixIcon: Icon(LucideIcons.globe),
                  ),
                ),
                AppSpacing.gapMd,
                FormBuilderTextField(
                  name: 'postalCode',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Postal Code',
                    hintText: '12345',
                    prefixIcon: Icon(LucideIcons.mailbox),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.numeric(
                      errorText: 'Please enter a valid postal code',
                    ),
                  ]),
                ),
              ],

              AppSpacing.gapXl,

              // Professional Information Section
              Row(
                children: [
                  Icon(
                    LucideIcons.briefcase,
                    size: Responsive.iconSize(
                      context,
                      mobile: 20,
                      tablet: 22,
                      desktop: 24,
                    ),
                    color: context.theme.colorScheme.primary,
                  ),
                  AppSpacing.gapSm,
                  Text(
                    AppTranslationKey.professionalInfo.tr,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapMd,

              FormBuilderTextField(
                name: 'organization',
                decoration: InputDecoration(
                  labelText: 'Organization',
                  hintText: 'Ministry of Health',
                  prefixIcon: Icon(LucideIcons.building),
                ),
              ),

              AppSpacing.gapMd,

              if (context.isLargerThanMobile) ...[
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'department',
                        decoration: InputDecoration(
                          labelText: 'Department',
                          hintText: 'Emergency Medicine',
                          prefixIcon: Icon(LucideIcons.building2),
                        ),
                      ),
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'jobTitle',
                        decoration: InputDecoration(
                          labelText: 'Job Title',
                          hintText: 'Clinical Officer',
                          prefixIcon: Icon(LucideIcons.userCheck),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                FormBuilderTextField(
                  name: 'department',
                  decoration: InputDecoration(
                    labelText: 'Department',
                    hintText: 'Emergency Medicine',
                    prefixIcon: Icon(LucideIcons.building2),
                  ),
                ),
                AppSpacing.gapMd,
                FormBuilderTextField(
                  name: 'jobTitle',
                  decoration: InputDecoration(
                    labelText: 'Job Title',
                    hintText: 'Clinical Officer',
                    prefixIcon: Icon(LucideIcons.userCheck),
                  ),
                ),
              ],

              AppSpacing.gapMd,

              FormBuilderTextField(
                name: 'specialization',
                decoration: InputDecoration(
                  labelText: 'Specialization',
                  hintText: 'General Practice',
                  prefixIcon: Icon(LucideIcons.stethoscope),
                ),
              ),

              AppSpacing.gapXxl,
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarUnsupported() {
    Common.quickToast(
      type: ToastificationType.info,
      title: 'Avatar upload unavailable',
      description: 'A typed profile-photo upload endpoint is required.',
    );
  }
}
