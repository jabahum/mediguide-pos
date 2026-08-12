import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/features/navigation/presentation/controllers/main_navigation_controller.dart';
import 'package:user_app/l10n/app_translations.dart';
import 'package:user_app/features/all_actions/presentation/screens/all_actions_page.dart';
import 'package:user_app/features/home/presentation/screens/home_page.dart';
import 'package:user_app/features/home/presentation/screens/guest_home_page.dart';
import 'package:user_app/features/guidelines/presentation/screens/publication_catalogue_page.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/authentication/presentation/screens/login_page.dart';
import 'package:user_app/features/profile/presentation/screens/profile_page.dart';
import 'package:user_app/features/calculators/presentation/screens/tools_page.dart';
import 'package:user_app/core/constants/app_dimensions.dart';
import 'package:user_app/core/widgets/offline_banner.dart';

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  static const _authenticatedPages = <Widget>[
    HomePage(),
    AllActionsPage(),
    ToolsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavigationIndexProvider);
    final authenticated = ref.watch(
      authControllerProvider.select(
        (value) => value.valueOrNull?.isAuthenticated ?? false,
      ),
    );
    final pages = authenticated
        ? _authenticatedPages
        : const <Widget>[
            GuestHomePage(),
            PublicationCataloguePage(embedded: true),
            ToolsPage(),
            LoginPage(),
          ];
    final destinations = [
      (LucideIcons.house, AppTranslationKey.home),
      (
        authenticated ? LucideIcons.grid3x3 : LucideIcons.bookOpenText,
        authenticated ? AppTranslationKey.moreInfo : 'Guidelines',
      ),
      (LucideIcons.calculator, AppTranslationKey.tools),
      (LucideIcons.user, authenticated ? AppTranslationKey.profile : 'Sign in'),
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FlexColorScheme.themedSystemNavigationBar(
        context,
        noAppBar: true,
        systemNavBarStyle: FlexSystemNavBarStyle.navigationBar,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < AppDimensions.compactNavigationBreakpoint;
          final content = Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: IndexedStack(index: currentIndex, children: pages),
              ),
            ],
          );
          return Scaffold(
            body: compact
                ? content
                : Row(
                    children: [
                      SafeArea(
                        child: NavigationRail(
                          selectedIndex: currentIndex,
                          labelType: NavigationRailLabelType.all,
                          onDestinationSelected: (index) =>
                              ref
                                      .read(
                                        mainNavigationIndexProvider.notifier,
                                      )
                                      .state =
                                  index,
                          destinations: [
                            for (final destination in destinations)
                              NavigationRailDestination(
                                icon: Icon(destination.$1),
                                label: Text(destination.$2),
                              ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: content),
                    ],
                  ),
            bottomNavigationBar: compact
                ? BottomNavigationBar(
                    type: BottomNavigationBarType.fixed,
                    currentIndex: currentIndex,
                    onTap: (index) =>
                        ref.read(mainNavigationIndexProvider.notifier).state =
                            index,
                    items: [
                      for (final destination in destinations)
                        BottomNavigationBarItem(
                          icon: Icon(destination.$1),
                          label: destination.$2,
                        ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }
}
