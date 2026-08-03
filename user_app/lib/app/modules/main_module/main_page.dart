import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../routes/app_pages.dart';
import '../../translations/app_translations.dart';
import '../../features/navigation/main_navigation_controller.dart';

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  static const _routes = [
    AppRoutes.home,
    AppRoutes.allActions,
    AppRoutes.tools,
    AppRoutes.profile,
  ];

  void _selectTab(WidgetRef ref, int index) {
    if (ref.read(mainNavigationIndexProvider) == index) return;
    ref.read(mainNavigationIndexProvider.notifier).state = index;
    Get.offNamed(_routes[index], id: 1);
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings, WidgetRef ref) {
    Get.routing.args = settings.arguments;
    GetPage<dynamic>? matchingPage;
    for (final page in AppPages.pages) {
      if (page.name == settings.name) {
        matchingPage = page;
        break;
      }
    }
    matchingPage ??= AppPages.pages.firstWhere(
      (page) => page.name == AppRoutes.home,
    );
    if (settings.name != matchingPage.name) {
      ref.read(mainNavigationIndexProvider.notifier).state = 0;
    }
    return GetPageRoute<dynamic>(
      settings: settings,
      page: matchingPage.page,
      binding: matchingPage.binding,
      transition: matchingPage.transition ?? Transition.fadeIn,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavigationIndexProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FlexColorScheme.themedSystemNavigationBar(
        context,
        noAppBar: true,
        systemNavBarStyle: FlexSystemNavBarStyle.navigationBar,
      ),
      child: Scaffold(
        body: Navigator(
          key: Get.nestedKey(1),
          initialRoute: AppRoutes.home,
          onGenerateRoute: (settings) => _onGenerateRoute(settings, ref),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: (index) => _selectTab(ref, index),
          items: [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.house),
              label: AppTranslationKey.home,
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.grid3x3),
              label: AppTranslationKey.moreInfo,
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.calculator),
              label: AppTranslationKey.tools,
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              label: AppTranslationKey.profile,
            ),
          ],
        ),
      ),
    );
  }
}
