import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/date_utils.dart';
import 'package:user_app/core/utils/responsive.dart';

import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/home/presentation/controllers/home_controller.dart';
import 'package:user_app/features/home/presentation/controllers/home_state.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/features/outbreaks/data/repositories/outbreak_repository.dart';
import 'package:user_app/features/outbreaks/presentation/providers/outbreak_providers.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/section_header.dart';

part '../widgets/home_page_home_app_bar.dart';
part '../widgets/home_page_clinical_search_card.dart';
part '../widgets/home_page_home_quick_action.dart';
part '../widgets/home_page_quick_action_grid.dart';
part '../widgets/home_page_quick_action_card.dart';
part '../widgets/home_page_continue_reading_section.dart';
part '../widgets/home_page_continue_reading_card.dart';
part '../widgets/home_page_guidelines_preview_list.dart';
part '../widgets/home_page_guideline_preview.dart';
part '../widgets/home_page_home_guideline_tile.dart';
part '../widgets/home_page_guideline_category_chip.dart';
part '../widgets/home_page_no_recent_guidelines_card.dart';
part '../widgets/home_page_logged_in_outbreak_banner.dart';

final homeOutbreakBannerProvider =
    FutureProvider.autoDispose<List<PublicOutbreak>>((ref) async {
      final enabled = ref.watch(outbreakFeatureEnabledProvider);
      if (!enabled) return const <PublicOutbreak>[];
      final page = await ref
          .watch(outbreakRepositoryProvider)
          .outbreaks(query: const OutbreakQuery(status: 'active'));
      final primary = selectPrimaryOutbreak(page.items);
      return primary == null ? const <PublicOutbreak>[] : [primary];
    });

class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.greetingHour})
    : assert(greetingHour == null || (greetingHour >= 0 && greetingHour <= 23));

  /// Overrides the local clock for previews/tests.
  final int? greetingHour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    final home = ref.watch(homeControllerProvider);

    final data = home.valueOrNull ?? const HomeState();

    final controller = ref.read(homeControllerProvider.notifier);

    final user = ref.watch(
      authControllerProvider.select((value) => value.valueOrNull?.user),
    );

    final userName = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()
        : 'Healthcare Professional';

    final professionalContext = <String>[
      if (user?.jobTitle.trim().isNotEmpty == true)
        user!.jobTitle.trim()
      else if (user?.role != null)
        user!.role!.label,
      if (user?.organization.trim().isNotEmpty == true)
        user!.organization.trim(),
    ].join(' · ');

    final greeting = _greetingFor(greetingHour ?? DateTime.now().hour);
    final notificationUnreadCount =
        ref.watch(notificationUnreadCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: colors.surface,

      appBar: _HomeAppBar(
        greeting: greeting,
        userName: userName,
        professionalContext: professionalContext,
        notificationUnreadCount: notificationUnreadCount,
        onNotifications: () {
          AppNavigator.push(AppRoutes.notifications);
        },
      ),

      body: _buildBody(
        context: context,
        ref: ref,
        home: home,
        data: data,
        controller: controller,
      ),
    );
  }

  static String _greetingFor(int hour) {
    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  Widget _buildBody({
    required BuildContext context,
    required WidgetRef ref,
    required AsyncValue<HomeState> home,
    required HomeState data,
    required HomeController controller,
  }) {
    // ---------------------------------------------------------
    // Initial loading
    // ---------------------------------------------------------

    if (home.isLoading && !data.hasContent) {
      return const AppLoadingView(message: 'Loading MediGuide...');
    }

    // ---------------------------------------------------------
    // Initial error
    // ---------------------------------------------------------

    if (home.hasError && !data.hasContent) {
      return AppErrorView(
        error: home.error ?? 'Unable to load home content',
        onRetry: controller.refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          context.responsiveHorizontalPadding,
          AppSpacing.md,
          context.responsiveHorizontalPadding,
          AppSpacing.xxxl,
        ),
        children: [
          // ---------------------------------------------------
          // Background refresh
          // ---------------------------------------------------
          if (home.isLoading && data.hasContent) ...[
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              child: LinearProgressIndicator(minHeight: 3),
            ),
            AppSpacing.md.gap,
          ],

          // ---------------------------------------------------
          // Search
          // ---------------------------------------------------
          _ClinicalSearchCard(
            onTap: () {
              AppNavigator.push(AppRoutes.search);
            },
          ),

          if (ref.watch(homeOutbreakBannerProvider).valueOrNull case [
            final active,
            ...,
          ]) ...[
            AppSpacing.lg.gap,
            _LoggedInOutbreakBanner(outbreak: active),
          ],

          AppSpacing.lg.gap,

          // ---------------------------------------------------
          // Quick actions
          // ---------------------------------------------------
          SectionHeader(title: 'Quick access'),

          AppSpacing.sm.gap,

          _QuickActionGrid(
            actions: [
              _HomeQuickAction(
                icon: LucideIcons.bookOpenText,
                title: 'Guidelines',
                subtitle: 'Clinical guidance',
                onTap: () async {
                  await AppNavigator.push(AppRoutes.publicGuidelines);
                },
              ),

              _HomeQuickAction(
                icon: LucideIcons.pill,
                title: 'Drug Index',
                subtitle: 'Medicines reference',
                onTap: () async {
                  await AppNavigator.push(AppRoutes.drugIndex);
                },
              ),

              _HomeQuickAction(
                icon: LucideIcons.calculator,
                title: 'Calculators',
                subtitle: 'Clinical tools',
                onTap: () async {
                  await AppNavigator.push(
                    AppRoutes.tools,
                    extra: const {'initialTab': 1},
                  );
                },
              ),

              _HomeQuickAction(
                icon: LucideIcons.hospital,
                title: 'Facilities',
                subtitle: 'Find health services',
                onTap: () async {
                  await AppNavigator.push(AppRoutes.healthFacilities);
                },
              ),
            ],
          ),

          AppSpacing.xl.gap,

          // ---------------------------------------------------
          // Continue reading
          // ---------------------------------------------------
          if (data.continueReadingItems.isNotEmpty) ...[
            SectionHeader(
              title: 'Continue reading',
              onSeeAll: () {
                AppNavigator.push(AppRoutes.library);
              },
            ),

            AppSpacing.sm.gap,

            _ContinueReadingSection(
              items: data.continueReadingItems.take(3).toList(growable: false),
              onOpen: (progress) {
                _continueReading(ref, progress);
              },
            ),

            AppSpacing.xl.gap,
          ],

          // ---------------------------------------------------
          // Recent guideline updates
          // ---------------------------------------------------
          SectionHeader(title: 'Recent updates', onSeeAll: _openAllGuidelines),

          AppSpacing.sm.gap,

          if (data.recentlyUpdatedGuidelines.isNotEmpty)
            _GuidelinesPreviewList(
              guidelines: data.recentlyUpdatedGuidelines
                  .take(4)
                  .toList(growable: false),
              onOpenGuideline: (guideline) {
                _openGuideline(ref, guideline);
              },
            )
          else
            _NoRecentGuidelinesCard(onBrowse: _openAllGuidelines),

          // ---------------------------------------------------
          // Completely empty
          // ---------------------------------------------------
          if (!data.hasContent && data.recentlyUpdatedGuidelines.isEmpty) ...[
            AppSpacing.xl.gap,

            EmptyState.noData(
              title: 'No content available',
              description:
                  'Clinical guidelines and tools will appear here when available.',
              actionLabel: 'Refresh',
              onAction: () {
                controller.refresh();
              },
            ),
          ],
        ],
      ),
    );
  }

  static void _openAllGuidelines() {
    AppNavigator.push(AppRoutes.publicGuidelines);
  }

  static Future<void> _openGuideline(
    WidgetRef ref,
    GuidelinePublication guideline,
  ) async {
    await AppNavigator.push(AppRoutes.publicGuideline(guideline.id));

    ref.invalidate(homeControllerProvider);
  }

  static Future<void> _continueReading(
    WidgetRef ref,
    ReadingProgress progress,
  ) async {
    final guidelineId = progress.guidelineId.trim();

    if (guidelineId.isEmpty) {
      return;
    }

    try {
      final section = progress.currentSection.trim();

      final location = AppRoutes.readPublicGuideline(guidelineId);

      await AppNavigator.push(
        section.isEmpty
            ? location
            : '$location?section=${Uri.encodeQueryComponent(section)}',
      );

      ref.invalidate(homeControllerProvider);
    } catch (_) {
      //
      // Keep the existing home state.
      //
      // A temporary offline/navigation failure
      // should not remove continue-reading data.
      //
    }
  }
}

/// ===========================================================================
/// APP BAR
/// ===========================================================================
