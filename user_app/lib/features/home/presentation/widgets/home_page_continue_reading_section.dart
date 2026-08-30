part of '../screens/home_page.dart';

class _ContinueReadingSection extends StatelessWidget {
  const _ContinueReadingSection({required this.items, required this.onOpen});

  final List<ReadingProgress> items;

  final ValueChanged<ReadingProgress> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == items.length - 1 ? 0 : AppSpacing.sm,
            ),
            child: _ContinueReadingCard(
              progress: items[index],
              onTap: () {
                onOpen(items[index]);
              },
            ),
          ),
      ],
    );
  }
}
