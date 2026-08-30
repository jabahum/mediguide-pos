import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/storage/local_storage_service.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/core/utils/responsive.dart';

import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_state.dart';
import 'package:user_app/features/authentication/presentation/controllers/biometric_controller.dart';

import 'package:user_app/features/profile/presentation/screens/change_password_bottom_sheet.dart';

import 'package:user_app/features/settings/presentation/controllers/app_update_controller.dart';
import 'package:user_app/features/settings/presentation/controllers/language_controller.dart';

import 'package:user_app/shared/widgets/language_bottom_sheet.dart';
import 'package:user_app/shared/widgets/theme_bottom_sheet.dart';
import 'package:user_app/shared/widgets/user_avatar.dart';

part '../widgets/profile_page_profile_header_card.dart';
part '../widgets/profile_page_settings_section.dart';
part '../widgets/profile_page_settings_tile.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    final auth = ref.watch(authControllerProvider).valueOrNull;

    final isAuthBusy = auth?.phase == AuthPhase.refreshing;

    final biometric = ref.watch(biometricControllerProvider).valueOrNull;

    final languageName = ref.watch(
      languageControllerProvider.select(
        (value) =>
            value.valueOrNull?.displayName ?? AppTranslationKey.english.tr,
      ),
    );

    final updateState = ref.watch(appUpdateControllerProvider);

    final isCheckingForUpdate = updateState.isLoading;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile & Settings',
              style: TextStyle(
                fontSize: Responsive.fontSize(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 24,
                ),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Account, preferences and support',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        elevation: context.isMobile ? 0 : 2,
      ),

      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          context.responsiveHorizontalPadding,
          context.responsiveVerticalPadding,
          context.responsiveHorizontalPadding,
          Responsive.doubleValue(context, mobile: 64, tablet: 80, desktop: 96),
        ),
        children: [
          // ===============================================================
          // PROFILE
          // ===============================================================
          _ProfileHeaderCard(onEditProfile: () => _openEditProfile(ref)),

          AppSpacing.xl.gap,

          // ===============================================================
          // ACCOUNT
          // ===============================================================
          _SettingsSection(
            title: AppTranslationKey.accountSettings.tr,
            description: 'Manage your profile and account security.',
            children: [
              _SettingsTile(
                icon: LucideIcons.userRound,
                title: AppTranslationKey.editProfile.tr,
                subtitle: AppTranslationKey.updatePersonalInformation.tr,
                onTap: () {
                  AppNavigator.push(AppRoutes.editProfile);
                },
              ),

              _SettingsTile(
                icon: LucideIcons.badgeCheck,
                title: 'Professional context',
                subtitle:
                    'View your role, organisation and health facility context',
                onTap: () {
                  AppNavigator.push(AppRoutes.healthFacilities);
                },
              ),

              _SettingsTile(
                icon: LucideIcons.bell,
                title: 'Notifications',
                subtitle: 'Review alerts and notification history',
                onTap: () {
                  AppNavigator.push(AppRoutes.notifications);
                },
              ),

              _SettingsTile(
                icon: LucideIcons.lockKeyhole,
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
                enabled: biometric?.available == true,
                showChevron: false,
                trailing: Switch(
                  value: biometric?.enabled ?? false,
                  onChanged: biometric?.available == true
                      ? (value) {
                          _toggleBiometric(context, ref, value);
                        }
                      : null,
                ),
                onTap: biometric?.available == true
                    ? () {
                        _toggleBiometric(
                          context,
                          ref,
                          !(biometric?.enabled ?? false),
                        );
                      }
                    : null,
              ),
            ],
          ),

          AppSpacing.xl.gap,

          // ===============================================================
          // APP PREFERENCES
          // ===============================================================
          _SettingsSection(
            title: AppTranslationKey.appPreferences.tr,
            description: 'Control offline access, appearance and language.',
            children: [
              _SettingsTile(
                icon: LucideIcons.cloudDownload,
                title: 'Offline Content',
                subtitle: 'Manage downloaded guidelines, storage and updates',
                onTap: () {
                  AppNavigator.push(AppRoutes.offlineContent);
                },
              ),

              _SettingsTile(
                icon: LucideIcons.bellRing,
                title: 'Notification preferences',
                subtitle: 'Channels, alert categories, quiet hours and devices',
                onTap: () {
                  AppNavigator.push(AppRoutes.notificationPreferences);
                },
              ),

              _SettingsTile(
                icon: LucideIcons.palette,
                title: AppTranslationKey.theme.tr,
                subtitle: _getThemeDisplayName(),
                onTap: () {
                  ThemeBottomSheet.show();
                },
              ),

              _SettingsTile(
                icon: LucideIcons.languages,
                title: AppTranslationKey.language.tr,
                subtitle: languageName,
                onTap: () {
                  LanguageBottomSheet.show();
                },
              ),
            ],
          ),

          AppSpacing.xl.gap,

          // ===============================================================
          // SUPPORT
          // ===============================================================
          _SettingsSection(
            title: AppTranslationKey.supportAndAbout.tr,
            description: 'Help, app information and legal resources.',
            children: [
              _SettingsTile(
                icon: LucideIcons.circleHelp,
                title: AppTranslationKey.helpCenter.tr,
                subtitle: AppTranslationKey.getHelpAndSupport.tr,
                onTap: () {
                  AppNavigator.push(AppRoutes.helpCenter);
                },
              ),

              _SettingsTile(
                icon: LucideIcons.messageCircleQuestion,
                title: AppTranslationKey.frequentlyAskedQuestions.tr,
                subtitle: AppTranslationKey.getAnswersToCommonQuestions.tr,
                onTap: () {
                  AppNavigator.push(AppRoutes.faq);
                },
              ),

              _SettingsTile(
                icon: LucideIcons.refreshCw,
                title: AppTranslationKey.checkForUpdate.tr,
                subtitle: isCheckingForUpdate
                    ? AppTranslationKey.checkingForUpdates.tr
                    : AppTranslationKey.upToDate.tr,
                showChevron: false,
                trailing: isCheckingForUpdate
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.chevronRight),
                onTap: isCheckingForUpdate
                    ? null
                    : () {
                        _checkForUpdate(context, ref);
                      },
              ),

              _SettingsTile(
                icon: LucideIcons.info,
                title: AppTranslationKey.aboutMediGuide.tr,
                subtitle: AppTranslationKey.appVersionAndInfo.tr,
                onTap: () {
                  AppNavigator.push(AppRoutes.aboutUs);
                },
              ),

              _SettingsTile(
                icon: LucideIcons.fileText,
                title: AppTranslationKey.termsAndPrivacy.tr,
                subtitle: AppTranslationKey.legalInformation.tr,
                onTap: () {
                  AppNavigator.push(AppRoutes.termsAndConditions);
                },
              ),

              _SettingsTile(
                icon: LucideIcons.shieldCheck,
                title: 'Privacy & data use',
                subtitle: 'Data handling, offline storage and AI safety',
                onTap: () {
                  AppNavigator.push(AppRoutes.termsAndConditions);
                },
              ),

              _SettingsTile(
                icon: LucideIcons.star,
                title: AppTranslationKey.rateApp.tr,
                subtitle: AppTranslationKey.rateUsOnAppStore.tr,
                onTap: () {
                  _rateApp(context);
                },
              ),
            ],
          ),

          AppSpacing.xl.gap,

          // ===============================================================
          // ACCOUNT ACTIONS
          // ===============================================================
          _SettingsSection(
            title: AppTranslationKey.accountActions.tr,
            description: 'Session and account management.',
            children: [
              _SettingsTile(
                icon: LucideIcons.logOut,
                title: AppTranslationKey.signOut.tr,
                subtitle: AppTranslationKey.signOutOfAccount.tr,
                iconColor: colors.primary,
                titleColor: colors.primary,
                showChevron: false,
                trailing: isAuthBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(LucideIcons.chevronRight, color: colors.primary),
                onTap: isAuthBusy
                    ? null
                    : () {
                        _logout(context, ref);
                      },
              ),

              _SettingsTile(
                icon: LucideIcons.trash2,
                title: AppTranslationKey.deleteAccount.tr,
                subtitle: AppTranslationKey.permanentlyDeleteAccount.tr,
                iconColor: colors.error,
                titleColor: colors.error,
                showChevron: false,
                trailing: Icon(LucideIcons.chevronRight, color: colors.error),
                onTap: isAuthBusy
                    ? null
                    : () {
                        _deleteAccount(ref);
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // EDIT PROFILE
  // ========================================================================

  Future<void> _openEditProfile(WidgetRef ref) async {
    final result = await AppNavigator.push(AppRoutes.editProfile);

    if (result == true) {
      await ref.read(authControllerProvider.notifier).refreshProfile();
    }
  }

  // ========================================================================
  // BIOMETRICS
  // ========================================================================

  Future<void> _toggleBiometric(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final success = await ref
        .read(biometricControllerProvider.notifier)
        .setEnabled(value);

    if (!context.mounted) {
      return;
    }

    if (success) {
      AppMessage.success(
        context,
        value
            ? AppTranslationKey.biometricEnabled.tr
            : AppTranslationKey.biometricDisabled.tr,
      );

      return;
    }

    AppMessage.error(
      context,
      AppTranslationKey.failedToUpdateBiometricSettings.tr,
    );
  }

  // ========================================================================
  // LOGOUT
  // ========================================================================

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppNavigator.dialog<bool>(
      child: AlertDialog(
        icon: const Icon(LucideIcons.logOut),
        title: Text(AppTranslationKey.signOut.tr),
        content: const Text('Are you sure you want to sign out of MediGuide?'),
        actions: [
          TextButton(
            onPressed: () {
              AppNavigator.pop(false);
            },
            child: Text(AppTranslationKey.cancel.tr),
          ),
          FilledButton(
            onPressed: () {
              AppNavigator.pop(true);
            },
            child: Text(AppTranslationKey.signOut.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).logout();

      AppNavigator.go(AppRoutes.login);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      AppMessage.error(context, AppTranslationKey.error.tr);
    }
  }

  // ========================================================================
  // DELETE ACCOUNT
  // ========================================================================

  Future<void> _deleteAccount(WidgetRef ref) async {
    await AppNavigator.dialog<void>(
      child: AlertDialog(
        icon: Icon(
          LucideIcons.triangleAlert,
          color: AppNavigator.theme.colorScheme.error,
        ),
        title: Text(AppTranslationKey.deleteAccount.tr),
        content: const Text(
          'Account deletion is not available in this version. '
          'Please contact support for assistance with account removal.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              AppNavigator.pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // RATE
  // ========================================================================

  Future<void> _rateApp(BuildContext context) async {
    try {
      final review = InAppReview.instance;

      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing();
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      AppMessage.error(context, AppTranslationKey.ratingFailed.tr);
    }
  }

  // ========================================================================
  // UPDATE
  // ========================================================================

  Future<void> _checkForUpdate(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref
          .read(appUpdateControllerProvider.notifier)
          .check();

      if (result == null || !context.mounted) {
        return;
      }

      final description = switch (result) {
        AppUpdateResult.unsupported =>
          'Updates are only supported on Android devices',

        AppUpdateResult.downloading =>
          AppTranslationKey.updateDownloadingInBackground.tr,

        AppUpdateResult.upToDate => AppTranslationKey.appIsUpToDate.tr,
      };

      AppMessage.info(context, description);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      AppMessage.error(context, AppTranslationKey.failedToCheckForUpdates.tr);
    }
  }

  // ========================================================================
  // THEME
  // ========================================================================

  String _getThemeDisplayName() {
    final savedTheme = PreferenceUtils.getString(
      SharedPreferencesKeys.themeMode,
      ThemeModes.system,
    );

    return switch (savedTheme) {
      ThemeModes.light => AppTranslationKey.lightMode.tr,

      ThemeModes.dark => AppTranslationKey.darkMode.tr,

      _ => AppTranslationKey.systemDefault.tr,
    };
  }

  // ========================================================================
  // PASSWORD
  // ========================================================================

  void _showChangePasswordBottomSheet() {
    AppNavigator.bottomSheet(
      child: const ChangePasswordBottomSheet(),
      backgroundColor: AppNavigator.theme.colorScheme.surface,
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

// ===========================================================================
// PROFILE HEADER
// ===========================================================================
