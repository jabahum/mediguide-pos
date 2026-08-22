import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:toastification/toastification.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/theme/app_theme.dart';
import 'package:user_app/core/utils/common.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:user_app/shared/providers/connectivity_provider.dart';
import 'package:user_app/features/settings/presentation/controllers/language_controller.dart';
import 'package:user_app/l10n/app_translations.dart';
import 'package:user_app/core/debug/debug_tools_overlay.dart';
import 'package:user_app/features/notifications/domain/notification_action_resolver.dart';
import 'package:user_app/features/home/presentation/screens/guest_home_page.dart';
import 'package:user_app/features/home/presentation/screens/home_page.dart';
import 'package:user_app/features/outbreaks/presentation/providers/outbreak_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class MediGuideApp extends ConsumerWidget {
  const MediGuideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authControllerProvider);
    ref.watch(backendReconnectProvider);
    final router = ref.watch(appRouterProvider);
    ref.listen(outbreakBannerEnabledProvider, (_, next) {
      if (!next.hasValue) return;
      ref.invalidate(guestHomeOutbreaksProvider);
      ref.invalidate(homeOutbreakBannerProvider);
      ref.invalidate(publicOutbreaksProvider);
      ref.invalidate(publicSituationReportsProvider);
    });
    ref.listen(firebaseOpenedMessageProvider, (_, message) {
      final data = message.valueOrNull?.data;
      if (data == null) return;
      _invalidateOutbreakContent(ref, data);
      final target = NotificationActionResolver.fromPushData(data);
      final deliveryId = data['delivery_id']?.toString().trim() ?? '';
      if (deliveryId.isNotEmpty) {
        final messageId = data['message_id']?.toString().trim();
        unawaited(
          (() async {
            final repository = ref.read(notificationRepositoryProvider);
            final eventSuffix = messageId?.isNotEmpty == true
                ? messageId!
                : deliveryId;
            await repository.recordOpen(
              deliveryId,
              eventId: 'push-open-$eventSuffix',
            );
            if (target != null) {
              await repository.recordClick(
                deliveryId,
                eventId: 'push-click-$eventSuffix',
              );
            }
          })(),
        );
      }
      if (target?.location case final location?) {
        router.push(location);
      } else if (target?.externalUri case final uri?) {
        unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
      }
    });
    ref.listen(firebaseForegroundMessageProvider, (_, message) {
      final foreground = message.valueOrNull;
      if (foreground == null) return;
      _invalidateOutbreakContent(ref, foreground.data);
      unawaited(
        (() async {
          final repository = ref.read(notificationRepositoryProvider);
          if (repository.userId.trim().isEmpty) return;
          try {
            await repository.list(page: 1, perPage: 30);
          } finally {
            ref.read(notificationInboxRefreshProvider.notifier).state++;
            ref.invalidate(notificationUnreadCountProvider);
          }
        })(),
      );
    });
    final languageCode =
        ref.watch(languageControllerProvider).valueOrNull?.currentCode ?? 'en';
    AppTranslation.setLocale(Locale(languageCode));
    final themeMode = ref.watch(
      appSettingsControllerProvider.select(
        (settings) => settings.materialThemeMode,
      ),
    );

    return GestureDetector(
      onTap: Common.dismissKeyboard,
      child: ToastificationWrapper(
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: AppTranslation.locale,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => DebugToolsOverlay(
            child: ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: const [
                Breakpoint(start: 0, end: 450, name: MOBILE),
                Breakpoint(start: 451, end: 800, name: TABLET),
                Breakpoint(start: 801, end: 1920, name: DESKTOP),
                Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _invalidateOutbreakContent(WidgetRef ref, Map<String, dynamic> data) {
  final type = [data['action_type'], data['resource_type'], data['type']]
      .whereType<Object>()
      .map((value) => value.toString().toLowerCase())
      .join(' ');
  if (!type.contains('outbreak') && !type.contains('situation_report')) return;
  ref.invalidate(guestHomeOutbreaksProvider);
  ref.invalidate(homeOutbreakBannerProvider);
  ref.invalidate(publicOutbreaksProvider);
  ref.invalidate(publicSituationReportsProvider);
  final resourceId = data['resource_id']?.toString().trim() ?? '';
  if (resourceId.isEmpty) return;
  if (type.contains('situation_report')) {
    ref.invalidate(publicSituationReportProvider(resourceId));
  } else {
    ref.invalidate(publicOutbreakProvider(resourceId));
  }
}
