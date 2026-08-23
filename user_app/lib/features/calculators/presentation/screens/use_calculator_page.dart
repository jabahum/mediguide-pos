import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/features/calculators/presentation/controllers/use_calculator_controller.dart';
import 'package:user_app/features/calculators/presentation/widgets/native_clinical_tool.dart';
import 'package:user_app/shared/models/models.dart';

class UseCalculatorPage extends ConsumerStatefulWidget {
  const UseCalculatorPage({super.key, this.arguments});
  final Object? arguments;
  @override
  ConsumerState<UseCalculatorPage> createState() => _UseCalculatorPageState();
}

class _UseCalculatorPageState extends ConsumerState<UseCalculatorPage> {
  late final UseCalculatorRequest _request;
  @override
  void initState() {
    super.initState();
    _request = _requestFromArguments(widget.arguments);
  }

  UseCalculatorRequest _requestFromArguments(Object? arguments) {
    if (arguments is Calculator) {
      return UseCalculatorRequest(id: arguments.id, calculator: arguments);
    }
    if (arguments is Map) {
      return UseCalculatorRequest(
        id:
            arguments['calculatorId']?.toString().trim() ??
            arguments['id']?.toString().trim() ??
            '',
      );
    }
    return UseCalculatorRequest(id: arguments?.toString().trim() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final provider = useCalculatorControllerProvider(_request);
    final asyncState = ref.watch(provider);
    final calculator = asyncState.valueOrNull?.calculator;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              calculator?.name ?? 'Clinical Tool',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (calculator != null)
              Text(
                'Reviewed JSON schema',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reload tool',
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => ref.invalidate(provider),
          ),
          AppSpacing.xs.gap,
        ],
      ),
      body: asyncState.when(
        loading: () =>
            const AppLoadingView(message: 'Loading clinical tool...'),
        error: (error, stackTrace) => AppErrorView(
          error: error,
          title: 'Clinical tool unavailable',
          message:
              'A clinically reviewed JSON-schema version has not been published for this tool, or its cached schema is unavailable.',
          onRetry: () => ref.invalidate(provider),
        ),
        data: (state) => Column(
          children: [
            _CalculatorContextBar(calculator: state.calculator),
            Expanded(
              child: NativeClinicalTool(
                definition: state.definition.definition,
                initialValues: state.responses,
                onChanged: ref.read(provider.notifier).saveResponses,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorContextBar extends StatelessWidget {
  const _CalculatorContextBar({required this.calculator});
  final Calculator calculator;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.calculator,
              size: 18,
              color: colors.primary,
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  calculator.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${calculator.type.label} • v${calculator.version}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
