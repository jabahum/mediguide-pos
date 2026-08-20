import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/constants/app_spacing.dart';
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

  double _pageProgress = 0;

  bool _canGoBack = false;
  bool _canGoForward = false;

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

    final calculator = asyncState.valueOrNull?.calculator;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              calculator?.name ?? 'Clinical Calculator',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            if (calculator != null)
              Text(
                'Clinical tool',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Previous calculator page',
            onPressed: _canGoBack ? _goBack : null,
            icon: const Icon(LucideIcons.arrowLeft),
          ),

          IconButton(
            tooltip: 'Next calculator page',
            onPressed: _canGoForward ? _goForward : null,
            icon: const Icon(LucideIcons.arrowRight),
          ),

          IconButton(
            tooltip: 'Reload calculator',
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: asyncState.hasValue ? _reloadWebView : null,
          ),

          AppSpacing.xs.gap,
        ],
        bottom: _pageProgress > 0 && _pageProgress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _pageProgress,
                  minHeight: 3,
                ),
              )
            : null,
      ),

      body: asyncState.when(
        // ----------------------------------------------------
        // Initial loading
        // ----------------------------------------------------
        loading: () {
          return const AppLoadingView(message: 'Loading calculator...');
        },

        // ----------------------------------------------------
        // Controller/content error
        // ----------------------------------------------------
        error: (error, stackTrace) {
          return AppErrorView(
            error: error,
            title: 'Failed to load calculator',
            message: 'The calculator could not be loaded.',
            onRetry: () {
              ref.invalidate(provider);
            },
          );
        },

        // ----------------------------------------------------
        // Calculator content
        // ----------------------------------------------------
        data: (state) {
          if (state.webViewError != null) {
            return AppErrorView(
              error: state.webViewError!,
              title: 'Failed to load calculator',
              message: 'The calculator page could not be displayed.',
              onRetry: () {
                _retryWebView(controller);
              },
            );
          }

          return Column(
            children: [
              // ------------------------------------------------
              // Clinical calculator header
              // ------------------------------------------------
              _CalculatorContextBar(calculator: state.calculator),

              // ------------------------------------------------
              // WebView
              // ------------------------------------------------
              Expanded(
                child: Stack(
                  children: [
                    InAppWebView(
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,

                        isInspectable: !kReleaseMode,

                        useShouldOverrideUrlLoading: true,

                        javaScriptCanOpenWindowsAutomatically: false,

                        supportMultipleWindows: false,

                        geolocationEnabled: false,

                        allowContentAccess: false,

                        allowFileAccess: false,

                        allowFileAccessFromFileURLs: false,

                        allowUniversalAccessFromFileURLs: false,

                        thirdPartyCookiesEnabled: false,

                        mediaPlaybackRequiresUserGesture: true,

                        safeBrowsingEnabled: true,

                        transparentBackground: false,
                      ),

                      onWebViewCreated: (webViewController) async {
                        _webViewController = webViewController;

                        await _loadCalculatorHtml(webViewController, state);
                      },

                      onLoadStart: (controllerInstance, url) {
                        controller.webViewLoading();

                        if (mounted) {
                          setState(() {
                            _pageProgress = 0;
                          });
                        }
                      },

                      onProgressChanged: (_, progress) {
                        if (!mounted) {
                          return;
                        }

                        setState(() {
                          _pageProgress = progress / 100;
                        });
                      },

                      onLoadStop: (webViewController, url) async {
                        controller.webViewReady();

                        await _updateNavigationState(webViewController);

                        if (!mounted) {
                          return;
                        }

                        setState(() {
                          _pageProgress = 1;
                        });
                      },

                      onReceivedError: (_, request, error) {
                        //
                        // Some WebView resources such
                        // as images/fonts can fail without
                        // making the actual calculator
                        // unusable.
                        //
                        // Only promote a main document
                        // failure to a full-screen error
                        // where supported by the package.
                        //
                        if (request.isForMainFrame == false) {
                          return;
                        }

                        controller.webViewFailed(error.description);
                      },

                      onReceivedHttpError: (_, request, response) {
                        if (request.isForMainFrame == false) {
                          return;
                        }

                        final statusCode = response.statusCode;

                        if (statusCode != null && statusCode >= 400) {
                          controller.webViewFailed(
                            'Calculator returned HTTP $statusCode.',
                          );
                        }
                      },

                      shouldOverrideUrlLoading: (_, action) async {
                        final requested = action.request.url?.toString();

                        if (requested == null) {
                          return NavigationActionPolicy.CANCEL;
                        }

                        final allowed = calculatorNavigationAllowed(
                          requested,
                          state.baseUrl,
                        );

                        return allowed
                            ? NavigationActionPolicy.ALLOW
                            : NavigationActionPolicy.CANCEL;
                      },
                    ),

                    // ----------------------------------------
                    // WebView loading overlay
                    // ----------------------------------------
                    if (!state.isWebViewReady)
                      Positioned.fill(
                        child: ColoredBox(
                          color: Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withValues(alpha: 0.92),
                          child: const AppLoadingView(
                            message: 'Preparing calculator...',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ========================================================================
  // LOAD CALCULATOR
  // ========================================================================

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

  // ========================================================================
  // NAVIGATION
  // ========================================================================

  Future<void> _updateNavigationState(InAppWebViewController controller) async {
    final canGoBack = await controller.canGoBack();

    final canGoForward = await controller.canGoForward();

    if (!mounted) {
      return;
    }

    setState(() {
      _canGoBack = canGoBack;
      _canGoForward = canGoForward;
    });
  }

  Future<void> _goBack() async {
    final controller = _webViewController;

    if (controller == null) {
      return;
    }

    if (await controller.canGoBack()) {
      await controller.goBack();

      await _updateNavigationState(controller);
    }
  }

  Future<void> _goForward() async {
    final controller = _webViewController;

    if (controller == null) {
      return;
    }

    if (await controller.canGoForward()) {
      await controller.goForward();

      await _updateNavigationState(controller);
    }
  }

  // ========================================================================
  // RELOAD
  // ========================================================================

  Future<void> _reloadWebView() async {
    final controller = _webViewController;

    if (controller == null) {
      return;
    }

    try {
      ref
          .read(useCalculatorControllerProvider(_request).notifier)
          .webViewLoading();

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

  // ========================================================================
  // RETRY
  // ========================================================================

  Future<void> _retryWebView(UseCalculatorController controller) async {
    final provider = useCalculatorControllerProvider(_request);

    final current = ref.read(provider).valueOrNull;

    if (current == null) {
      ref.invalidate(provider);

      return;
    }

    final webViewController = _webViewController;

    if (webViewController == null) {
      ref.invalidate(provider);

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

// ===========================================================================
// CALCULATOR CONTEXT
// ===========================================================================

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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),

                Text(
                  'Enter the required clinical values below.',
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

// ===========================================================================
// NAVIGATION SECURITY
// ===========================================================================

@visibleForTesting
bool calculatorNavigationAllowed(String requestedUrl, String baseUrl) {
  final requested = Uri.tryParse(requestedUrl);

  final base = Uri.tryParse(baseUrl);

  if (requested == null || base == null) {
    return false;
  }

  // WebView startup/navigation internals.
  if (requested.scheme == 'about') {
    return requestedUrl == 'about:blank';
  }

  // Resources generated by the calculator itself.
  if (requested.scheme == 'data' || requested.scheme == 'blob') {
    return true;
  }

  // Explicitly block other schemes such as:
  // javascript:, file:, intent:, tel:, mailto:, etc.
  if (requested.scheme != 'https' && requested.scheme != 'http') {
    return false;
  }

  // Calculator navigation is constrained to the
  // same origin as the supplied calculator base URL.
  return requested.scheme == base.scheme &&
      requested.host == base.host &&
      requested.port == base.port;
}
