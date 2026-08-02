import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';

import '../../data/services/main_service.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_state.dart';
import '../../features/auth/biometric_controller.dart';
import '../../providers/core_providers.dart';
import '../../routes/app_pages.dart';
import '../../translations/app_translations.dart';
import '../../utils/app_spacing.dart';
import '../../utils/common.dart';
import '../../utils/constants.dart';
import '../../utils/preference_utils.dart';
import '../../utils/responsive.dart';
import '../../widgets/language_bottom_sheet.dart';
import '../../widgets/theme_bottom_sheet.dart';
import '../../widgets/user_avatar.dart';

import 'change_password_bottom_sheet.dart';
import 'edit_profile_dialog.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.theme.colorScheme;
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final isLoading = auth?.phase == AuthPhase.refreshing;
    final biometric = ref.watch(biometricControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          AppTranslationKey.profile.tr,
          style: TextStyle(
            fontSize: Responsive.fontSize(
              context,
              mobile: 20.0,
              tablet: 22.0,
              desktop: 24.0,
            ),
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: context.isMobile ? 0 : 2,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveHorizontalPadding,
          vertical: context.responsiveVerticalPadding,
        ),
        children: [
          _ProfileHeaderCard(onEditProfile: () => _showEditProfileDialog(ref)),

          AppSpacing.lg.gap,

          _SettingsSection(
            title: AppTranslationKey.accountSettings.tr,
            children: [
              _SettingsTile(
                icon: LucideIcons.user,
                title: AppTranslationKey.editProfile.tr,
                subtitle: AppTranslationKey.updatePersonalInformation.tr,
                onTap: () => _showEditProfileDialog(ref),
              ),
              _SettingsTile(
                icon: LucideIcons.lock,
                title: AppTranslationKey.changePassword.tr,
                subtitle: AppTranslationKey.updateSecurityCredentials.tr,
                onTap: _showChangePasswordBottomSheet,
              ),
              _SettingsTile(
                icon: LucideIcons.fingerprint,
                title: AppTranslationKey.biometricAuthentication.tr,
                subtitle: biometric?.available == true
                    ? AppTranslationKey.biometricAuthDesc.tr
                    : AppTranslationKey.biometricNotAvailable.tr,
                trailing: Switch(
                  value: biometric?.enabled ?? false,
                  onChanged: biometric?.available == true
                      ? (value) => _toggleBiometric(ref, value)
                      : null,
                ),
                showChevron: false,
              ),
            ],
          ),

          AppSpacing.lg.gap,

          _SettingsSection(
            title: AppTranslationKey.appPreferences.tr,
            children: [
              _SettingsTile(
                icon: LucideIcons.palette,
                title: AppTranslationKey.theme.tr,
                subtitle: _getThemeDisplayName(),
                onTap: () => ThemeBottomSheet.show(),
              ),
              _SettingsTile(
                icon: LucideIcons.languages,
                title: AppTranslationKey.language.tr,
                subtitle: _languageDisplayName(),
                onTap: () => LanguageBottomSheet.show(),
              ),
            ],
          ),

          AppSpacing.lg.gap,

          _SettingsSection(
            title: AppTranslationKey.supportAndAbout.tr,
            children: [
              _SettingsTile(
                icon: LucideIcons.circleHelp,
                title: AppTranslationKey.helpCenter.tr,
                subtitle: AppTranslationKey.getHelpAndSupport.tr,
                onTap: () => Get.toNamed(AppRoutes.helpCenter),
              ),
              _SettingsTile(
                icon: LucideIcons.messageCircleQuestion,
                title: AppTranslationKey.frequentlyAskedQuestions.tr,
                subtitle: AppTranslationKey.getAnswersToCommonQuestions.tr,
                onTap: () => Get.toNamed(AppRoutes.faq),
              ),
              Obx(
                () => _SettingsTile(
                  icon: LucideIcons.download,
                  title: AppTranslationKey.checkForUpdate.tr,
                  subtitle: MainService.to.isCheckingForUpdate.value
                      ? AppTranslationKey.checkingForUpdates.tr
                      : AppTranslationKey.upToDate.tr,
                  trailing: MainService.to.isCheckingForUpdate.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.chevronRight),
                  showChevron: false,
                  onTap: MainService.to.isCheckingForUpdate.value
                      ? null
                      : () => MainService.to.checkForUpdate(),
                ),
              ),
              _SettingsTile(
                icon: LucideIcons.info,
                title: AppTranslationKey.aboutMediGuide.tr,
                subtitle: AppTranslationKey.appVersionAndInfo.tr,
                onTap: () => Get.toNamed(AppRoutes.aboutUs),
              ),
              _SettingsTile(
                icon: LucideIcons.fileText,
                title: AppTranslationKey.termsAndPrivacy.tr,
                subtitle: AppTranslationKey.legalInformation.tr,
                onTap: () => Get.toNamed(AppRoutes.termsAndConditions),
              ),
              _SettingsTile(
                icon: LucideIcons.star,
                title: AppTranslationKey.rateApp.tr,
                subtitle: AppTranslationKey.rateUsOnAppStore.tr,
                onTap: _rateApp,
              ),
            ],
          ),

          AppSpacing.lg.gap,

          _SettingsSection(
            title: AppTranslationKey.accountActions.tr,
            children: [
              _SettingsTile(
                icon: LucideIcons.logOut,
                title: AppTranslationKey.signOut.tr,
                subtitle: AppTranslationKey.signOutOfAccount.tr,
                iconColor: cs.primary,
                titleColor: cs.primary,
                trailing: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.chevronRight),
                showChevron: false,
                onTap: isLoading ? null : () => _logout(ref),
              ),
              _SettingsTile(
                icon: LucideIcons.trash2,
                title: AppTranslationKey.deleteAccount.tr,
                subtitle: AppTranslationKey.permanentlyDeleteAccount.tr,
                iconColor: cs.error,
                titleColor: cs.error,
                trailing: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(LucideIcons.chevronRight, color: cs.error),
                showChevron: false,
                onTap: isLoading ? null : () => _deleteAccount(ref),
              ),
            ],
          ),

          SizedBox(
            height: Responsive.doubleValue(
              context,
              mobile: 48.0,
              tablet: 64.0,
              desktop: 80.0,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog(WidgetRef ref) async {
    final result = await Get.dialog(
      const EditProfileDialog(),
      barrierDismissible: false,
    );

    if (result == true) {
      await ref.read(authControllerProvider.notifier).refreshProfile();
    }
  }

  Future<void> _toggleBiometric(WidgetRef ref, bool value) async {
    final success = await ref
        .read(biometricControllerProvider.notifier)
        .setEnabled(value);

    if (success) {
      Common.quickToast(
        type: ToastificationType.success,
        title: AppTranslationKey.biometricAuthentication.tr,
        description: value
            ? AppTranslationKey.biometricEnabled.tr
            : AppTranslationKey.biometricDisabled.tr,
      );
    } else {
      Common.quickToast(
        type: ToastificationType.error,
        title: AppTranslationKey.biometricAuthentication.tr,
        description: AppTranslationKey.failedToUpdateBiometricSettings.tr,
      );
    }
  }

  Future<void> _logout(WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).logout();
      Get.offAllNamed(AppRoutes.login);
    } catch (error) {
      Common.quickToast(
        type: ToastificationType.error,
        title: AppTranslationKey.error.tr,
        description: Common.parseApiError(error),
      );
    }
  }

  Future<void> _deleteAccount(WidgetRef ref) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppTranslationKey.deleteAccount.tr),
        content: const Text(
          'Account deletion is not available in this version. Contact support for assistance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(AppTranslationKey.cancel.tr),
          ),
        ],
      ),
    );
    if (confirmed == true) return;
  }

  Future<void> _rateApp() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing();
      }
    } catch (_) {
      Common.quickToast(
        type: ToastificationType.error,
        title: AppTranslationKey.error.tr,
        description: AppTranslationKey.ratingFailed.tr,
      );
    }
  }

  String _languageDisplayName() {
    try {
      return LanguageController.to.currentLanguage?.shortDisplayName ??
          AppTranslationKey.english.tr;
    } catch (_) {
      return AppTranslationKey.english.tr;
    }
  }

  String _getThemeDisplayName() {
    final savedTheme = PreferenceUtils.getString(
      SharedPreferencesKeys.themeMode,
      ThemeModes.system,
    );

    switch (savedTheme) {
      case ThemeModes.light:
        return AppTranslationKey.lightMode.tr;
      case ThemeModes.dark:
        return AppTranslationKey.darkMode.tr;
      case ThemeModes.system:
      default:
        return AppTranslationKey.systemDefault.tr;
    }
  }

  void _showChangePasswordBottomSheet() {
    Get.bottomSheet(
      const ChangePasswordBottomSheet(),
      backgroundColor: Get.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
    );
  }
}

class _ProfileHeaderCard extends ConsumerWidget {
  final VoidCallback onEditProfile;

  const _ProfileHeaderCard({required this.onEditProfile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.theme.colorScheme;
    final user = ref.watch(
      authControllerProvider.select((value) => value.valueOrNull?.user),
    );
    final name = user?.name ?? AppTranslationKey.user.tr;
    final specialization = user?.specialization ?? '';
    final avatarUrl = user?.avatar.isNotEmpty == true
        ? ref.read(backendApiServiceProvider).getFileUrl(filename: user!.avatar)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: cs.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: cs.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              UserAvatar(
                name: name,
                avatarUrl: avatarUrl,
                radius: Responsive.doubleValue(
                  context,
                  mobile: 42.0,
                  tablet: 52.0,
                  desktop: 60.0,
                ),
              ),
              Material(
                color: cs.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onEditProfile,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      LucideIcons.pencil,
                      color: cs.onPrimary,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          AppSpacing.md.gap,

          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),

          if (specialization.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                specialization,
                style: context.textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1)
                    Divider(
                      height: 1,
                      indent: 64,
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final effectiveIconColor = iconColor ?? cs.primary;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: effectiveIconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: effectiveIconColor, size: 21),
      ),
      title: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: titleColor,
        ),
      ),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing:
          trailing ??
          (showChevron
              ? Icon(LucideIcons.chevronRight, color: cs.onSurfaceVariant)
              : null),
    );
  }
}
