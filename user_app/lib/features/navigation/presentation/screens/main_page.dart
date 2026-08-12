import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/features/navigation/presentation/controllers/main_navigation_controller.dart';
import 'package:user_app/features/home/presentation/screens/home_page.dart';
import 'package:user_app/features/home/presentation/screens/guest_home_page.dart';
import 'package:user_app/features/guidelines/presentation/screens/publication_catalogue_page.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/library/presentation/screens/my_library_page.dart';
import 'package:user_app/features/navigation/presentation/screens/guest_more_page.dart';
import 'package:user_app/features/profile/presentation/screens/profile_page.dart';
import 'package:user_app/features/calculators/presentation/screens/tools_page.dart';
import 'package:user_app/features/search/presentation/screens/global_search_page.dart';
import 'package:user_app/core/constants/app_dimensions.dart';
import 'package:user_app/core/widgets/offline_banner.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  static const _authenticatedPages = <Widget>[
    HomePage(),
    GlobalSearchPage(embedded: true),
    MyLibraryPage(embedded: true),
    ToolsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      authControllerProvider.select(
        (value) => value.valueOrNull?.isAuthenticated ?? false,
      ),
      (previous, next) {
        if (previous == null || previous == next) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(mainNavigationIndexProvider.notifier).state = 0;
          }
        });
      },
    );
    final requestedIndex = ref.watch(mainNavigationIndexProvider);
    final authenticated = ref.watch(
      authControllerProvider.select(
        (value) => value.valueOrNull?.isAuthenticated ?? false,
      ),
    );
    final pages = authenticated
        ? _authenticatedPages
        : const <Widget>[
            GuestHomePage(),
            GlobalSearchPage(embedded: true),
            PublicationCataloguePage(embedded: true),
            ToolsPage(),
            GuestMorePage(),
          ];
    final currentIndex = requestedIndex.clamp(0, pages.length - 1);
    final destinations = <(IconData, String)>[
      (LucideIcons.house, 'Home'),
      (LucideIcons.search, 'Search'),
      (
        authenticated ? LucideIcons.library : LucideIcons.bookOpenText,
        authenticated ? 'My Library' : 'Guidelines',
      ),
      (LucideIcons.grid2x2, 'Tools'),
      (
        authenticated ? LucideIcons.user : LucideIcons.ellipsis,
        authenticated ? 'Profile' : 'More',
      ),
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
                ? NavigationBar(
                    selectedIndex: currentIndex,
                    onDestinationSelected: (index) =>
                        ref.read(mainNavigationIndexProvider.notifier).state =
                            index,
                    destinations: [
                      for (final destination in destinations)
                        NavigationDestination(
                          icon: Icon(destination.$1),
                          selectedIcon: Icon(destination.$1, fill: 1),
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
