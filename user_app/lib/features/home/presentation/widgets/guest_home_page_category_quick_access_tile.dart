part of '../screens/guest_home_page.dart';

class _CategoryQuickAccessTile extends StatelessWidget {
  const _CategoryQuickAccessTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final icon = _categoryIcon(label);

    return Semantics(
      button: true,
      label: 'Browse $label guidelines',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('guest-category-$label'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: colors.onSecondaryContainer,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _categoryIcon(String category) {
    final value = category.toLowerCase();

    // Maternal / reproductive health
    if (value.contains('maternal') ||
        value.contains('pregnan') ||
        value.contains('reproductive') ||
        value.contains('obstetric')) {
      return LucideIcons.heartHandshake;
    }

    // Child health
    if (value.contains('child') ||
        value.contains('paediatric') ||
        value.contains('pediatric') ||
        value.contains('newborn') ||
        value.contains('neonatal')) {
      return LucideIcons.baby;
    }

    // Diabetes / endocrine
    if (value.contains('diabetes') || value.contains('endocr')) {
      return LucideIcons.droplets;
    }

    // HIV / AIDS
    if (value.contains('hiv') || value.contains('aids')) {
      return LucideIcons.ribbon;
    }

    // TB / respiratory
    if (value.contains('tb') ||
        value.contains('tuberculosis') ||
        value.contains('respiratory') ||
        value.contains('pulmonary')) {
      return LucideIcons.activity;
    }

    // Cardiovascular
    if (value.contains('cardio') ||
        value.contains('heart') ||
        value.contains('hypertension')) {
      return LucideIcons.heartPulse;
    }

    // Mental health
    if (value.contains('mental') || value.contains('psychiatr')) {
      return LucideIcons.brain;
    }

    // Emergency / critical care
    if (value.contains('emergency') ||
        value.contains('critical') ||
        value.contains('acute')) {
      return LucideIcons.siren;
    }

    // Infectious / communicable diseases
    if (value.contains('infect') ||
        value.contains('communicable') ||
        value.contains('disease')) {
      return LucideIcons.bug;
    }

    // Nutrition
    if (value.contains('nutrition') || value.contains('malnutrition')) {
      return LucideIcons.apple;
    }

    // Surgery
    if (value.contains('surgery') || value.contains('surgical')) {
      return LucideIcons.cross;
    }

    // Medicines / pharmacy
    if (value.contains('medicine') ||
        value.contains('drug') ||
        value.contains('pharmacy') ||
        value.contains('pharmaceutical')) {
      return LucideIcons.pill;
    }

    // Laboratory
    if (value.contains('laboratory') ||
        value.contains('lab') ||
        value.contains('diagnostic')) {
      return LucideIcons.flaskConical;
    }

    // Eye / ophthalmology
    if (value.contains('eye') || value.contains('ophthalm')) {
      return LucideIcons.eye;
    }

    // Dental / oral
    if (value.contains('dental') || value.contains('oral')) {
      return LucideIcons.smile;
    }

    // Cancer / oncology
    if (value.contains('cancer') ||
        value.contains('oncology') ||
        value.contains('oncological')) {
      return LucideIcons.ribbon;
    }

    // General / default clinical guidance
    return LucideIcons.bookOpenText;
  }
}

// =============================================================================
// PUBLICATION CARD
// =============================================================================
