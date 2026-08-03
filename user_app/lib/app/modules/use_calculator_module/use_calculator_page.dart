import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/models.dart';
import '../../features/tools/use_calculator_controller.dart';
import '../../utils/loading.dart';
import '../../widgets/app_button.dart';

class UseCalculatorPage extends ConsumerStatefulWidget {
  const UseCalculatorPage({super.key});

  @override
  ConsumerState<UseCalculatorPage> createState() => _UseCalculatorPageState();
}

class _UseCalculatorPageState extends ConsumerState<UseCalculatorPage> {
  late final UseCalculatorRequest _request;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments;
    if (arguments is Calculator) {
      _request = UseCalculatorRequest(id: arguments.id, calculator: arguments);
    } else if (arguments is Map) {
      _request = UseCalculatorRequest(
        id:
            arguments['calculatorId']?.toString() ??
            arguments['id']?.toString() ??
            '',
      );
    } else {
      _request = UseCalculatorRequest(id: arguments?.toString() ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = useCalculatorControllerProvider(_request);
    final content = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(
        title: Text(content.valueOrNull?.calculator.name ?? 'Calculator'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: content.hasValue
                ? () => _webViewController?.reload()
                : null,
          ),
        ],
      ),
      body: content.when(
        loading: () => const _CalculatorLoading(label: 'Loading calculator...'),
        error: (error, _) => _CalculatorError(
          message: error.toString(),
          onRetry: () => ref.invalidate(provider),
        ),
        data: (state) {
          if (state.webViewError != null) {
            return _CalculatorError(
              message: state.webViewError!,
              onRetry: () => ref.invalidate(provider),
            );
          }
          return Stack(
            children: [
              InAppWebView(
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  isInspectable: true,
                ),
                onWebViewCreated: (controller) async {
                  _webViewController = controller;
                  await controller.loadData(
                    data: state.html,
                    baseUrl: WebUri(state.baseUrl),
                  );
                },
                onLoadStart: (_, _) =>
                    ref.read(provider.notifier).webViewLoading(),
                onLoadStop: (_, _) =>
                    ref.read(provider.notifier).webViewReady(),
                onReceivedError: (_, request, error) => ref
                    .read(provider.notifier)
                    .webViewFailed(error.description),
                onConsoleMessage: (_, message) => debugPrint(
                  'WebView Console [${message.messageLevel}]: ${message.message}',
                ),
              ),
              if (!state.isWebViewReady)
                Container(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withValues(alpha: 0.8),
                  child: const _CalculatorLoading(
                    label: 'Loading calculator page...',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CalculatorLoading extends StatelessWidget {
  const _CalculatorLoading({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Loading.large(),
        const SizedBox(height: 16),
        Text(label),
      ],
    ),
  );
}

class _CalculatorError extends StatelessWidget {
  const _CalculatorError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.triangleAlert,
            size: 64,
            color: context.theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Calculator',
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          AppButton(
            text: 'Retry',
            icon: LucideIcons.refreshCw,
            onPressed: onRetry,
            width: 200,
          ),
        ],
      ),
    ),
  );
}
