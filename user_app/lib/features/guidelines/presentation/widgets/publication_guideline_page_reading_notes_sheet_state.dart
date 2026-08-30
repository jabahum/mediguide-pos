part of '../screens/publication_guideline_page.dart';

class _ReadingNotesSheetState extends State<_ReadingNotesSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reading notes',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),

          AppSpacing.gapSm,

          Text(
            'Private notes are saved with your reading progress.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          AppSpacing.gapMd,

          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 8,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Add a private note about this guideline',
              border: OutlineInputBorder(),
            ),
          ),

          AppSpacing.gapMd,

          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context, _controller.text);
            },
            icon: const Icon(LucideIcons.check),
            label: const Text('Save note'),
          ),

          AppSpacing.gapSm,
        ],
      ),
    );
  }
}

// =============================================================================
// GUIDELINE OVERVIEW
// =============================================================================
