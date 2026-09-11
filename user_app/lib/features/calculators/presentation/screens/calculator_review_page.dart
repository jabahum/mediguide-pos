import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/config/app_config.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/features/calculators/presentation/controllers/calculator_review_controller.dart';
import 'package:user_app/features/calculators/presentation/widgets/native_clinical_tool.dart';

class CalculatorReviewPage extends ConsumerWidget {
  const CalculatorReviewPage({super.key, required this.versionId});

  final String versionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calculatorReviewControllerProvider(versionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Clinical tool review')),
      body: state.when(
        loading: () =>
            const AppLoadingView(message: 'Loading clinical tool preview...'),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'This unpublished preview is unavailable. Confirm that you are signed in with calculator.review permission and that the review session has not expired.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ref
                      .read(
                        calculatorReviewControllerProvider(versionId).notifier,
                      )
                      .refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (preview) => Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'UNPUBLISHED REVIEW DRAFT',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${AppConfig.current.flavor.label} · ${preview.toolName} v${preview.semanticVersion}\n'
                              'Tool ${preview.calculatorId} · Version ${preview.versionId}\n'
                              'Checksum ${preview.definitionChecksum}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add review comment',
                        onPressed: () => _comment(context, ref),
                        icon: const Icon(Icons.rate_review_outlined),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: NativeClinicalTool(definition: preview.definition)),
          ],
        ),
      ),
    );
  }

  Future<void> _comment(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review observation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 4000,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Record an immutable clinical review comment…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (comment == null || comment.trim().isEmpty || !context.mounted) return;
    try {
      await ref
          .read(calculatorReviewControllerProvider(versionId).notifier)
          .addComment(comment);
      if (context.mounted) {
        AppMessage.success(context, 'Review comment submitted');
      }
    } catch (_) {
      if (context.mounted) {
        AppMessage.error(context, 'The review comment could not be submitted.');
      }
    }
  }
}
