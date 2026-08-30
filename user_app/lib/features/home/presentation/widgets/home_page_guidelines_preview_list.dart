part of '../screens/home_page.dart';

class _GuidelinesPreviewList extends StatelessWidget {
  const _GuidelinesPreviewList({
    required this.guidelines,
    required this.onOpenGuideline,
  });

  final List<GuidelinePublication> guidelines;

  final void Function(GuidelinePublication guideline) onOpenGuideline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < guidelines.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == guidelines.length - 1 ? 0 : AppSpacing.sm,
            ),
            child: _GuidelinePreview(
              guideline: guidelines[index],
              onTap: () {
                onOpenGuideline(guidelines[index]);
              },
            ),
          ),
      ],
    );
  }
}
