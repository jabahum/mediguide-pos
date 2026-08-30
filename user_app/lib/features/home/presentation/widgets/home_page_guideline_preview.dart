part of '../screens/home_page.dart';

class _GuidelinePreview extends StatelessWidget {
  const _GuidelinePreview({required this.guideline, required this.onTap});

  final GuidelinePublication guideline;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final updatedAt = guideline.lastUpdated != null
        ? 'Updated ${AppDateUtils.formatDate(guideline.lastUpdated!)}'
        : 'Recently added';

    return _HomeGuidelineTile(
      title: guideline.title,
      category: guideline.programArea,
      updatedAt: updatedAt,
      onTap: onTap,
    );
  }
}
