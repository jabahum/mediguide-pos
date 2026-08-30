part of '../screens/notification_preferences_page.dart';

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
        AppSpacing.gapSm,
        Card(child: Column(children: children)),
      ],
    );
  }
}
