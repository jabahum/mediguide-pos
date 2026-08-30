import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/features/outbreaks/data/repositories/outbreak_repository.dart';
import 'package:user_app/features/outbreaks/presentation/providers/outbreak_providers.dart';
import 'package:user_app/shared/widgets/clinical_icon_tile.dart';
import 'package:user_app/shared/widgets/section_header.dart';

part '../widgets/guest_home_page_guest_search_card.dart';
part '../widgets/guest_home_page_active_outbreak_card.dart';
part '../widgets/guest_home_page_publication_sections.dart';
part '../widgets/guest_home_page_category_quick_access_grid.dart';
part '../widgets/guest_home_page_category_quick_access_tile.dart';
part '../widgets/guest_home_page_publication_card.dart';
part '../widgets/guest_home_page_program_area_badge.dart';
part '../widgets/guest_home_page_quick_action_grid.dart';
part '../widgets/guest_home_page_quick_action_card.dart';
part '../widgets/guest_home_page_quick_action.dart';
part '../widgets/guest_home_page_offline_access_card.dart';
part '../widgets/guest_home_page_empty_publications_card.dart';
part '../widgets/guest_home_page_publication_skeleton.dart';
part '../widgets/guest_home_page_section_error.dart';

final guestHomePublicationsProvider =
    FutureProvider.autoDispose<List<GuidelinePublication>>((ref) async {
      final page = await ref
          .watch(guidelinePublicationRepositoryProvider)
          .publications(page: 1, perPage: 12);

      return page.items;
    });

final guestHomeOutbreaksProvider =
    FutureProvider.autoDispose<List<PublicOutbreak>>((ref) async {
      final enabled = ref.watch(outbreakFeatureEnabledProvider);
      if (!enabled) return const <PublicOutbreak>[];
      final page = await ref
          .watch(outbreakRepositoryProvider)
          .outbreaks(query: const OutbreakQuery(status: 'active'));
      final primary = selectPrimaryOutbreak(page.items);
      return primary == null ? const <PublicOutbreak>[] : [primary];
    });

class GuestHomePage extends ConsumerWidget {
  const GuestHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publications = ref.watch(guestHomePublicationsProvider);

    final outbreaks = ref.watch(guestHomeOutbreaksProvider);

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      // =====================================================================
      // APP BAR
      // =====================================================================
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MediGuide',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Clinical guidance when you need it',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.push(AppRoutes.login);
            },
            icon: const Icon(LucideIcons.logIn, size: 18),
            label: const Text('Sign in'),
          ),
          AppSpacing.hGapSm,
        ],
      ),

      // =====================================================================
      // BODY
      // =====================================================================
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(guestHomePublicationsProvider);

          ref.invalidate(guestHomeOutbreaksProvider);

          await Future.wait([
            ref.read(guestHomePublicationsProvider.future),
            ref.read(guestHomeOutbreaksProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            Responsive.horizontalPadding(context),
            AppSpacing.md,
            Responsive.horizontalPadding(context),
            AppSpacing.xxxl,
          ),
          children: [
            // =================================================================
            // SEARCH
            // =================================================================
            _GuestSearchCard(
              onTap: () {
                context.push(AppRoutes.search);
              },
            ),

            AppSpacing.gapLg,

            // =================================================================
            // ACTIVE OUTBREAK
            // =================================================================
            outbreaks.when(
              loading: () => const LinearProgressIndicator(minHeight: 3),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) {
                if (items.isEmpty) {
                  return const SizedBox.shrink();
                }

                return _ActiveOutbreakCard(
                  outbreak: items.first,
                  activeCount: items.length,
                );
              },
            ),

            if (outbreaks.valueOrNull?.isNotEmpty == true) AppSpacing.gapXl,

            // =================================================================
            // QUICK ACCESS
            // =================================================================
            const SectionHeader(title: 'Quick access'),

            AppSpacing.gapSm,

            _QuickActionGrid(
              actions: [
                _QuickAction(
                  label: 'Drug Index',
                  icon: LucideIcons.pill,
                  route: AppRoutes.drugIndex,
                ),
                _QuickAction(
                  label: 'Calculators',
                  icon: LucideIcons.calculator,
                  route: AppRoutes.tools,
                ),
                _QuickAction(
                  label: 'Algorithms',
                  icon: LucideIcons.gitBranch,
                  route: AppRoutes.publicGuidelines,
                ),
                _QuickAction(
                  label: 'Procedures',
                  icon: LucideIcons.clipboardList,
                  route: AppRoutes.publicGuidelines,
                ),
              ],
            ),

            AppSpacing.gapXl,

            // =================================================================
            // PUBLICATIONS
            // =================================================================
            publications.when(
              loading: () => const _PublicationSkeleton(),
              error: (_, _) => _SectionError(
                onRetry: () {
                  ref.invalidate(guestHomePublicationsProvider);
                },
              ),
              data: (items) {
                return _PublicationSections(publications: items);
              },
            ),

            AppSpacing.gapXl,

            // =================================================================
            // OFFLINE
            // =================================================================
            _OfflineAccessCard(
              onTap: () {
                context.push(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SEARCH
// =============================================================================
