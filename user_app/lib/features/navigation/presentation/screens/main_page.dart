import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/features/navigation/presentation/controllers/main_navigation_controller.dart';
import 'package:user_app/l10n/app_translations.dart';
import 'package:user_app/features/all_actions/presentation/screens/all_actions_page.dart';
import 'package:user_app/features/home/presentation/screens/home_page.dart';
import 'package:user_app/features/profile/presentation/screens/profile_page.dart';
import 'package:user_app/features/calculators/presentation/screens/tools_page.dart';

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
