part of '../screens/guest_home_page.dart';

class _PublicationSections extends StatelessWidget {
  const _PublicationSections({required this.publications});

  final List<GuidelinePublication> publications;

  @override
  Widget build(BuildContext context) {
    if (publications.isEmpty) {
      return _EmptyPublicationsCard(
        onTap: () {
          context.push(AppRoutes.publicGuidelines);
        },
      );
    }

    final areas = publications
        .map((item) => item.programArea.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .take(8)
        .toList(growable: false);

    final latest = publications.take(4).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===================================================================
        // CLINICAL CATEGORIES
        // ===================================================================
        if (areas.isNotEmpty) ...[
          SectionHeader(
            title: 'Clinical categories',
            subtitle: 'Browse guidance by programme area',
            icon: LucideIcons.layoutGrid,
            onSeeAll: () {
              context.push(AppRoutes.publicGuidelines);
            },
          ),

          AppSpacing.gapSm,

          _CategoryQuickAccessGrid(
            categories: areas,
            onCategory: (area) {
              context.push(AppRoutes.publicGuidelinesForProgramArea(area));
            },
          ),

          AppSpacing.gapXl,
        ],

        // ===================================================================
        // LATEST GUIDANCE
        // ===================================================================
        SectionHeader(
          title: 'Latest guidance',
          subtitle: 'Recently published or updated',
          icon: LucideIcons.bookOpenText,
          onSeeAll: () {
            context.push(AppRoutes.publicGuidelines);
          },
        ),

        AppSpacing.gapSm,

        for (var index = 0; index < latest.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == latest.length - 1 ? 0 : AppSpacing.sm,
            ),
            child: _PublicationCard(publication: latest[index]),
          ),
      ],
    );
  }
}

// =============================================================================
// CATEGORY QUICK ACCESS
// =============================================================================
