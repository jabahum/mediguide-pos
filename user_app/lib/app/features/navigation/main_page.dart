import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/navigation/main_navigation_controller.dart';
import '../../translations/app_translations.dart';
import '../all_actions/all_actions_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import '../tools/tools_page.dart';

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  static const _pages = <Widget>[
    HomePage(),
    AllActionsPage(),
    ToolsPage(),
    ProfilePage(),
  ];

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
        body: IndexedStack(index: currentIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: (index) =>
              ref.read(mainNavigationIndexProvider.notifier).state = index,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(LucideIcons.house),
              label: AppTranslationKey.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(LucideIcons.grid3x3),
              label: AppTranslationKey.moreInfo,
            ),
            BottomNavigationBarItem(
              icon: const Icon(LucideIcons.calculator),
              label: AppTranslationKey.tools,
            ),
            BottomNavigationBarItem(
              icon: const Icon(LucideIcons.user),
              label: AppTranslationKey.profile,
            ),
          ],
        ),
      ),
    );
  }
}
