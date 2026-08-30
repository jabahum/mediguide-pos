import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/core/widgets/empty_state.dart';

import 'package:user_app/features/ai_assistant/data/models/ai_context.dart';
import 'package:user_app/features/ai_assistant/data/services/ai_context_service.dart';
import 'package:user_app/features/content/data/models/generic_page.dart';
import 'package:user_app/features/content/presentation/controllers/generic_viewer_controller.dart';
import 'package:user_app/features/content/presentation/controllers/generic_viewer_state.dart';
import 'package:user_app/features/content/presentation/widgets/generic_page_section.dart';

import 'package:user_app/shared/widgets/ai_context_button.dart';
import 'package:user_app/shared/widgets/html_styles.dart';

part '../widgets/generic_viewer_page_key_value_page.dart';
part '../widgets/generic_viewer_page_html_page.dart';
part '../widgets/generic_viewer_page_viewer_app_bar.dart';
part '../widgets/generic_viewer_page_section_navigation.dart';
part '../widgets/generic_viewer_page_page_description.dart';
part '../widgets/generic_viewer_page_html_content_card.dart';

class GenericViewerPage extends ConsumerStatefulWidget {
  const GenericViewerPage({super.key, this.argument, this.pageKey});

  final Object? argument;
  final String? pageKey;

  @override
  ConsumerState<GenericViewerPage> createState() => _GenericViewerPageState();
}

class _GenericViewerPageState extends ConsumerState<GenericViewerPage> {
  @override
  void initState() {
    super.initState();

    final argument = widget.argument;
    final pageKey = widget.pageKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref
          .read(genericViewerControllerProvider.notifier)
          .initialize(pageArgument: argument, pageKey: pageKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(genericViewerControllerProvider);

    final controller = ref.read(genericViewerControllerProvider.notifier);

    final contextService = ref.watch(aiContextServiceProvider);

    // =====================================================================
    // LOADING
    // =====================================================================

    if (state.isLoading) {
      return const Scaffold(
        body: AppLoadingView(message: 'Loading content...'),
      );
    }

    // =====================================================================
    // ERROR
    // =====================================================================

    if (state.errorMessage != null && state.page == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            state.pageTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: AppErrorView(
          error: state.errorMessage!,
          title: 'Unable to load content',
          message: 'This page could not be loaded. Please try again.',
          onRetry: () {
            controller.initialize(
              pageArgument: widget.argument,
              pageKey: widget.pageKey,
            );
          },
        ),
      );
    }

    // =====================================================================
    // EMPTY
    // =====================================================================

    if (!state.hasContent) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            state.pageTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: EmptyState.noData(
          title: 'No content available',
          description: 'This page does not have any content to display.',
        ),
      );
    }

    // =====================================================================
    // CONTENT
    // =====================================================================

    if (state.isKeyValueContent) {
      return _KeyValuePage(
        state: state,
        controller: controller,
        contextService: contextService,
      );
    }

    return _HtmlPage(
      state: state,
      controller: controller,
      contextService: contextService,
    );
  }
}

// ===========================================================================
// KEY / VALUE PAGE
// ===========================================================================
