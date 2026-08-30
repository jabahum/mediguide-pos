part of '../screens/outbreak_document_screens.dart';

class _ReaderChip extends StatelessWidget {
  const _ReaderChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Chip(avatar: Icon(icon, size: 16), label: Text(label)),
  );
}
