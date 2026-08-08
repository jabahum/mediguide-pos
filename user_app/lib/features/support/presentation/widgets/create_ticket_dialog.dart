import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/features/support/presentation/controllers/help_center_controller.dart';
import 'package:user_app/shared/models/models.dart';

/// Full-screen dialog for creating a new support ticket.
class CreateTicketDialog extends ConsumerStatefulWidget {
  const CreateTicketDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) {
        return const CreateTicketDialog();
      },
    );
  }

  @override
  ConsumerState<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends ConsumerState<CreateTicketDialog> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(helpCenterControllerProvider);

    final controller = ref.read(helpCenterControllerProvider.notifier);

    return PopScope(
      canPop: !state.isCreatingTicket,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Support Ticket'),
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(LucideIcons.x),
            onPressed: state.isCreatingTicket
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
          ),
          actions: [
            TextButton.icon(
              onPressed: state.isCreatingTicket
                  ? null
                  : () {
                      _submit(controller);
                    },
              icon: state.isCreatingTicket
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.save, size: 18),
              label: Text(state.isCreatingTicket ? 'Creating...' : 'Create'),
            ),
          ],
        ),
        body: SafeArea(
          child: FormBuilder(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: AppSpacing.pagePadding,
              children: [
                AppSpacing.contentGap,

                // ============================================
                // SUBJECT
                // ============================================
                FormBuilderTextField(
                  name: 'subject',
                  enabled: !state.isCreatingTicket,
                  decoration: const InputDecoration(
                    labelText: 'Subject *',
                    hintText: 'Brief description of your issue',
                    prefixIcon: Icon(LucideIcons.type),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.minLength(5),
                  ]),
                ),

                AppSpacing.fieldGap,

                // ============================================
                // CATEGORY
                // ============================================
                FormBuilderDropdown<String>(
                  name: 'category',
                  enabled: !state.isCreatingTicket,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(LucideIcons.tag),
                  ),
                  initialValue: 'General Question',
                  items: HelpCenterController.availableCategories.map((
                    category,
                  ) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  validator: FormBuilderValidators.required(),
                ),

                AppSpacing.fieldGap,

                // ============================================
                // PRIORITY
                // ============================================
                FormBuilderDropdown<TicketPriority>(
                  name: 'priority',
                  enabled: !state.isCreatingTicket,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    prefixIcon: Icon(LucideIcons.flag),
                  ),
                  initialValue: TicketPriority.normal,
                  items: TicketPriority.values.map((priority) {
                    return DropdownMenuItem<TicketPriority>(
                      value: priority,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: priority.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          AppSpacing.gapSm,
                          Text(priority.label),
                        ],
                      ),
                    );
                  }).toList(),
                  validator: FormBuilderValidators.required(),
                ),

                AppSpacing.fieldGap,

                // ============================================
                // DESCRIPTION
                // ============================================
                FormBuilderTextField(
                  name: 'description',
                  enabled: !state.isCreatingTicket,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Provide detailed information about your issue',
                    prefixIcon: Icon(LucideIcons.fileText),
                    alignLabelWithHint: true,
                  ),
                  minLines: 5,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.minLength(10),
                  ]),
                ),

                AppSpacing.sectionGap,

                // ============================================
                // SUBMIT BUTTON
                // ============================================
                FilledButton.icon(
                  onPressed: state.isCreatingTicket
                      ? null
                      : () {
                          _submit(controller);
                        },
                  icon: state.isCreatingTicket
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(LucideIcons.send),
                  label: Text(
                    state.isCreatingTicket
                        ? 'Creating ticket...'
                        : 'Create Ticket',
                  ),
                ),

                AppSpacing.gapLg,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(HelpCenterController controller) async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      return;
    }

    final values = _formKey.currentState!.value;

    final subject = values['subject']?.toString().trim() ?? '';

    final description = values['description']?.toString().trim() ?? '';

    final category = values['category']?.toString() ?? 'General Question';

    final priority =
        values['priority'] as TicketPriority? ?? TicketPriority.normal;

    final created = await controller.createTicket(
      subject: subject,
      description: description,
      category: category,
      priority: priority,
    );

    if (!mounted || !created) {
      return;
    }

    Navigator.of(context).pop();
  }
}
