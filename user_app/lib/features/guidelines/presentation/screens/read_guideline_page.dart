import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';

import 'package:user_app/features/ai_assistant/data/models/ai_context.dart';
import 'package:user_app/features/guidelines/presentation/controllers/read_guideline_controller.dart';
import 'package:user_app/features/guidelines/presentation/widgets/guideline_header.dart';
import 'package:user_app/features/guidelines/presentation/widgets/guideline_section.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/ai_context_button.dart';

class ReadGuidelinePage extends ConsumerStatefulWidget {
  const ReadGuidelinePage({super.key, this.arguments});

  final Object? arguments;

  @override
  ConsumerState<ReadGuidelinePage> createState() => _ReadGuidelinePageState();
}

class _ReadGuidelinePageState extends ConsumerState<ReadGuidelinePage> {
  late final ScrollController _scrollController;
  late final ReadGuidelineRequest _request;

  final Map<String, GlobalKey> _sectionKeys = {};

  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();

    _request = _resolveRequest();

    _scrollController = ScrollController()..addListener(_trackScroll);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();

    _scrollController
      ..removeListener(_trackScroll)
      ..dispose();

    super.dispose();
  }

  ReadGuidelineRequest _resolveRequest() {
    final arguments = widget.arguments;

    if (arguments is Guideline) {
      return ReadGuidelineRequest(id: arguments.id, guideline: arguments);
    }

    if (arguments is Map) {
      final id =
          arguments['guidelineId']?.toString().trim() ??
          arguments['id']?.toString().trim() ??
          '';

      return ReadGuidelineRequest(id: id);
    }

    return ReadGuidelineRequest(id: arguments?.toString().trim() ?? '');
  }

  void _trackScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final maxExtent = _scrollController.position.maxScrollExtent;

    if (maxExtent <= 0) {
      return;
    }

    final progress = (_scrollController.position.pixels / maxExtent).clamp(
      0.0,
      1.0,
    );

    final controller = ref.read(
      readGuidelineControllerProvider(_request).notifier,
    );

    controller.setProgress(progress);

    _saveDebounce?.cancel();

    _saveDebounce = Timer(const Duration(seconds: 2), () {
      controller.saveProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = readGuidelineControllerProvider(_request);

    final asyncState = ref.watch(provider);

    return asyncState.when(
      // ==================================================
      // LOADING
      // ==================================================
      loading: () {
        return const Scaffold(
          body: AppLoadingView(message: 'Loading guideline...'),
        );
      },

      // ==================================================
      // ERROR
      // ==================================================
      error: (error, stackTrace) {
        final noGuidelineSelected = _request.id.isEmpty;

        return Scaffold(
          appBar: AppBar(),
          body: AppErrorView(
            error: error,
            title: noGuidelineSelected
                ? 'No guideline selected'
                : 'Unable to load guideline',
            message: noGuidelineSelected
                ? 'Select a guideline to view its clinical content.'
                : 'The guideline could not be loaded. Please check your connection and try again.',
            onRetry: noGuidelineSelected
                ? null
                : () {
                    ref.invalidate(provider);
                  },
          ),
        );
      },

      // ==================================================
      // DATA
      // ==================================================
      data: (state) {
        return _buildReader(context, provider, state);
      },
    );
  }

  Widget _buildReader(
    BuildContext context,
    AutoDisposeAsyncNotifierProvider<
      ReadGuidelineController,
      ReadGuidelineState
    >
    provider,
    ReadGuidelineState state,
  ) {
    final controller = ref.read(provider.notifier);

    final hasSections = state.sections.isNotEmpty;

    // DefaultTabController cannot have length 0.
    if (!hasSections) {
      return Scaffold(
        appBar: _buildAppBar(
          context: context,
          state: state,
          controller: controller,
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GuidelineHeader(guideline: state.guideline),

              AppSpacing.contentGap,

              Text(
                'No structured sections are available for this guideline.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.theme.colorScheme.onSurfaceVariant,
                ),
              ),

              AppSpacing.xxl.gap,
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: state.sections.length,
      child: Scaffold(
        appBar: _buildAppBar(
          context: context,
          state: state,
          controller: controller,
          showTabs: true,
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GuidelineHeader(guideline: state.guideline),

              AppSpacing.contentGap,

              for (final section in state.sections)
                GuidelineSectionWidget(
                  key: _sectionKey(section),
                  section: section,
                  content: guidelineSectionContent(state.guideline, section),
                ),

              AppSpacing.xxl.gap,
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar({
    required BuildContext context,
    required ReadGuidelineState state,
    required ReadGuidelineController controller,
    bool showTabs = false,
  }) {
    return AppBar(
      title: Text(
        state.guideline.conditionName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.titleMedium,
      ),
      actions: [
        AiContextButton.iconButton(context: _guidelineContext(state)),

        IconButton(
          tooltip: state.isBookmarked
              ? 'Remove bookmark'
              : 'Bookmark guideline',
          onPressed: state.isMutating
              ? null
              : () {
                  _toggleBookmark(controller, state.isBookmarked);
                },
          icon: state.isMutating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  state.isBookmarked
                      ? LucideIcons.bookmark
                      : LucideIcons.bookmarkPlus,
                ),
        ),
      ],
      bottom: showTabs
          ? TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final section in state.sections) Tab(text: section.label),
              ],
              onTap: (index) {
                _navigateToSection(controller, state.sections[index]);
              },
            )
          : null,
    );
  }

  void _navigateToSection(
    ReadGuidelineController controller,
    GuidelineSection section,
  ) {
    controller.selectSection(section);

    final sectionContext = _sectionKey(section).currentContext;

    if (sectionContext == null) {
      return;
    }

    Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  GlobalKey _sectionKey(GuidelineSection section) {
    return _sectionKeys.putIfAbsent(section.fieldName, GlobalKey.new);
  }

  Future<void> _toggleBookmark(
    ReadGuidelineController controller,
    bool wasBookmarked,
  ) async {
    final success = await controller.toggleBookmark();

    if (!mounted) {
      return;
    }

    final navigatorContext = AppKeys.navigatorKey.currentContext;

    if (navigatorContext == null) {
      return;
    }

    if (success) {
      AppMessage.success(
        navigatorContext,
        wasBookmarked ? 'Bookmark removed' : 'Guideline bookmarked',
      );

      return;
    }

    AppMessage.error(navigatorContext, 'Failed to update bookmark');
  }

  AiContext _guidelineContext(ReadGuidelineState state) {
    final contents = <String, dynamic>{};

    for (final section in state.sections) {
      final content = guidelineSectionContent(state.guideline, section);

      if (content.trim().isEmpty) {
        continue;
      }

      contents[section.label] = content;
    }

    return ref
        .read(aiContextServiceProvider)
        .extractGuidelineContext(
          conditionName: state.guideline.conditionName,
          guidelineData: contents,
          guidelineId: state.guideline.id,
        );
  }
}
