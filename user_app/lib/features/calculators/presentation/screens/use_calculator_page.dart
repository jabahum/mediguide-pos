import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';

import 'package:user_app/features/calculators/presentation/controllers/use_calculator_controller.dart';
import 'package:user_app/shared/models/models.dart';

class UseCalculatorPage extends ConsumerStatefulWidget {
  const UseCalculatorPage({super.key, this.arguments});

  final Object? arguments;

  @override
  ConsumerState<UseCalculatorPage> createState() => _UseCalculatorPageState();
}

class _UseCalculatorPageState extends ConsumerState<UseCalculatorPage> {
  late final UseCalculatorRequest _request;

  InAppWebViewController? _webViewController;

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

    final controller = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(asyncState.valueOrNull?.calculator.name ?? 'Calculator'),
        actions: [
          IconButton(
            tooltip: 'Reload calculator',
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: asyncState.hasValue ? _reloadWebView : null,
          ),
        ],
      ),
      body: asyncState.when(
        // ==================================================
        // INITIAL LOADING
        // ==================================================
        loading: () {
          return const AppLoadingView(message: 'Loading calculator...');
        },

        // ==================================================
        // CONTROLLER / CONTENT ERROR
        // ==================================================
        error: (error, stackTrace) {
          return AppErrorView(
            error: error,
            title: 'Failed to Load Calculator',
            message: 'The calculator could not be loaded.',
            onRetry: () {
              ref.invalidate(provider);
            },
          );
        },

        // ==================================================
        // CALCULATOR CONTENT
        // ==================================================
        data: (state) {
          if (state.webViewError != null) {
            return AppErrorView(
              error: state.webViewError!,
              title: 'Failed to Load Calculator',
              message: state.webViewError!,
              onRetry: () {
                _retryWebView(controller);
              },
            );
          }

          return Stack(
            children: [
              InAppWebView(
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,

                  // Consider disabling this for release
                  // builds unless WebView inspection is
                  // intentionally required.
                  isInspectable: true,
                ),

                onWebViewCreated: (webViewController) async {
                  _webViewController = webViewController;

                  await _loadCalculatorHtml(webViewController, state);
                },

                onLoadStart: (_, _) {
                  controller.webViewLoading();
                },

                onLoadStop: (_, _) {
                  controller.webViewReady();
                },

                onReceivedError: (_, request, error) {
                  // Ignore failures from non-main-frame
                  // resources such as images or fonts.
                  // if (!request.isForMainFrame) {
                  //   return;
                  // }

                  controller.webViewFailed(error.description);
                },

                onConsoleMessage: (_, message) {
                  debugPrint(
                    'WebView Console '
                    '[${message.messageLevel}]: '
                    '${message.message}',
                  );
                },
              ),

              // ============================================
              // WEBVIEW LOADING OVERLAY
              // ============================================
              if (!state.isWebViewReady)
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0.88),
                    child: const AppLoadingView(
                      message: 'Loading calculator page...',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadCalculatorHtml(
    InAppWebViewController controller,
    UseCalculatorState state,
  ) async {
    try {
      await controller.loadData(
        data: state.html,
        baseUrl: WebUri(state.baseUrl),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ref
          .read(useCalculatorControllerProvider(_request).notifier)
          .webViewFailed(error.toString());
    }
  }

  Future<void> _reloadWebView() async {
    final controller = _webViewController;

    if (controller == null) {
      return;
    }

    try {
      await controller.reload();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ref
          .read(useCalculatorControllerProvider(_request).notifier)
          .webViewFailed(error.toString());
    }
  }

  Future<void> _retryWebView(UseCalculatorController controller) async {
    final current = ref
        .read(useCalculatorControllerProvider(_request))
        .valueOrNull;

    if (current == null) {
      ref.invalidate(useCalculatorControllerProvider(_request));

      return;
    }

    final webViewController = _webViewController;

    if (webViewController == null) {
      ref.invalidate(useCalculatorControllerProvider(_request));

      return;
    }

    controller.webViewLoading();

    try {
      await _loadCalculatorHtml(webViewController, current);
    } catch (error) {
      controller.webViewFailed(error.toString());
    }
  }
}
