import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/core/utils/loading.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/features/support/presentation/controllers/help_center_controller.dart';

/// Full screen dialog for creating a new support ticket
class CreateTicketDialog extends ConsumerStatefulWidget {
  const CreateTicketDialog({super.key});

  /// Show the full screen create ticket dialog
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (context) => const CreateTicketDialog(),
    );
  }

  @override
  ConsumerState<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends ConsumerState<CreateTicketDialog> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(helpCenterControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Support Ticket'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: controller.isCreatingTicket
                ? null
                : () => _submit(controller),
            icon: controller.isCreatingTicket
                ? const Loading.small()
                : const Icon(LucideIcons.save, size: 18),
            label: Text(controller.isCreatingTicket ? 'Creating...' : 'Create'),
          ),
        ],
        elevation: 1,
      ),
      body: FormBuilder(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [
            AppSpacing.contentGap,

            // Subject
            FormBuilderTextField(
              name: 'subject',
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

            // Category dropdown
            FormBuilderDropdown<String>(
              name: 'category',
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(LucideIcons.tag),
              ),
              initialValue: 'General Question',
              items: controller.availableCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              validator: FormBuilderValidators.required(),
            ),

            AppSpacing.fieldGap,

            // Priority dropdown
            FormBuilderDropdown<TicketPriority>(
              name: 'priority',
              decoration: const InputDecoration(
                labelText: 'Priority',
                prefixIcon: Icon(LucideIcons.flag),
              ),
              initialValue: TicketPriority.normal,
              items: TicketPriority.values
                  .map(
                    (priority) => DropdownMenuItem(
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
                    ),
                  )
                  .toList(),
              validator: FormBuilderValidators.required(),
            ),

            AppSpacing.fieldGap,

            // Description
            FormBuilderTextField(
              name: 'description',
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Provide detailed information about your issue',
                prefixIcon: Icon(LucideIcons.fileText),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              textInputAction: TextInputAction.newline,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(10),
              ]),
            ),

            AppSpacing.sectionGap,
          ],
        ),
      ),
    );
  }

  Future<void> _submit(HelpCenterController controller) async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;
    final created = await controller.createTicket(
      subject: values['subject'] as String,
      description: values['description'] as String,
      category: values['category'] as String,
      priority: values['priority'] as TicketPriority,
    );
    if (created && mounted) Navigator.pop(context);
  }
}
