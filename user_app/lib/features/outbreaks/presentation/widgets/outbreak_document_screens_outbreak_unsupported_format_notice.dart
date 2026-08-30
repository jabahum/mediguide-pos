part of '../screens/outbreak_document_screens.dart';

class OutbreakUnsupportedFormatNotice extends StatelessWidget {
  const OutbreakUnsupportedFormatNotice({super.key});

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: const ListTile(
      leading: Icon(LucideIcons.fileWarning),
      title: Text('Inline preview unavailable'),
      subtitle: Text(
        'This format cannot be rendered safely in the app. Download or open the authoritative original instead.',
      ),
    ),
  );
}
