import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/app_message.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';

import 'package:user_app/features/ai_assistant/data/models/ai_context.dart';
import 'package:user_app/features/guidelines/presentation/controllers/read_guideline_controller.dart';
import 'package:user_app/features/guidelines/presentation/widgets/guideline_header.dart';
import 'package:user_app/features/guidelines/presentation/widgets/guideline_section.dart';

import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/ai_context_button.dart';

part '../widgets/read_guideline_page_section_navigation_bar.dart';
part '../widgets/read_guideline_page_section_anchor.dart';
part '../widgets/read_guideline_page_no_structured_sections.dart';

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
  Timer? _visibleSectionDebounce;

  String? _visibleSectionField;

  @override
  void initState() {
    super.initState();

    _request = _resolveRequest();

    _scrollController = ScrollController()..addListener(_trackScroll);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _visibleSectionDebounce?.cancel();

    _scrollController
      ..removeListener(_trackScroll)
      ..dispose();

    super.dispose();
  }

  // =========================================================================
  // REQUEST
  // =========================================================================

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

  // =========================================================================
  // SCROLL / PROGRESS
  // =========================================================================

  void _trackScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;

    final maxExtent = position.maxScrollExtent;

    if (maxExtent > 0) {
      final progress = (position.pixels / maxExtent).clamp(0.0, 1.0);

      final controller = ref.read(
        readGuidelineControllerProvider(_request).notifier,
      );

      controller.setProgress(progress);

      _saveDebounce?.cancel();

      _saveDebounce = Timer(const Duration(seconds: 2), () {
        controller.saveProgress();
      });
    }

    _visibleSectionDebounce?.cancel();

    _visibleSectionDebounce = Timer(
      const Duration(milliseconds: 100),
      _updateVisibleSection,
    );
  }

  void _updateVisibleSection() {
    if (!mounted) {
      return;
    }

    String? nearestField;
    var nearestDistance = double.infinity;

    for (final entry in _sectionKeys.entries) {
      final context = entry.value.currentContext;

      final renderObject = context?.findRenderObject();

      if (renderObject is! RenderBox || !renderObject.attached) {
        continue;
      }

      final position = renderObject.localToGlobal(Offset.zero);

      //
      // Aim slightly below the app bar / section selector.
      //
      final distance = (position.dy - 140).abs();

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestField = entry.key;
      }
    }

    if (nearestField == null || nearestField == _visibleSectionField) {
      return;
    }

    setState(() {
      _visibleSectionField = nearestField;
    });
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final provider = readGuidelineControllerProvider(_request);

    final asyncState = ref.watch(provider);

    return asyncState.when(
      loading: () {
        return const Scaffold(
          body: AppLoadingView(message: 'Loading guideline...'),
        );
      },

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

      data: (state) {
        return _buildReader(context, provider, state);
      },
    );
  }

  Widget _buildReader(
    BuildContext context,
    ReadGuidelineControllerProvider provider,
    ReadGuidelineState state,
  ) {
    final controller = ref.read(provider.notifier);

    final hasSections = state.sections.isNotEmpty;

    return Scaffold(
      appBar: _buildAppBar(
        context: context,
        state: state,
        controller: controller,
      ),

      body: Column(
        children: [
          // ===============================================================
          // READING PROGRESS
          // ===============================================================
          // _ReadingProgressBar(progress: state.progress),

          // ===============================================================
          // SECTION NAVIGATION
          // ===============================================================
          if (hasSections)
            _SectionNavigationBar(
              sections: state.sections,
              selectedField: _visibleSectionField,
              onSelected: (section) {
                _navigateToSection(controller, section);
              },
            ),

          // ===============================================================
          // CONTENT
          // ===============================================================
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification ||
                    notification is ScrollEndNotification) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateVisibleSection();
                  });
                }

                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  Responsive.horizontalPadding(context),
                  AppSpacing.lg,
                  Responsive.horizontalPadding(context),
                  AppSpacing.xxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GuidelineHeader(guideline: state.guideline),

                    AppSpacing.contentGap,

                    if (!hasSections)
                      _NoStructuredSections(guideline: state.guideline)
                    else
                      for (final section in state.sections) ...[
                        _SectionAnchor(
                          key: _sectionKey(section),
                          child: GuidelineSectionWidget(
                            section: section,
                            content: guidelineSectionContent(
                              state.guideline,
                              section,
                            ),
                          ),
                        ),

                        AppSpacing.gapLg,
                      ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // APP BAR
  // =========================================================================

  PreferredSizeWidget _buildAppBar({
    required BuildContext context,
    required ReadGuidelineState state,
    required ReadGuidelineController controller,
  }) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      titleSpacing: AppSpacing.sm,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.guideline.conditionName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),

          if (_visibleSectionLabel(state.sections) != null)
            Text(
              _visibleSectionLabel(state.sections)!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
        ],
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
                      ? LucideIcons.bookmarkCheck
                      : LucideIcons.bookmarkPlus,
                ),
        ),

        AppSpacing.hGapXs,
      ],
    );
  }

  String? _visibleSectionLabel(List<GuidelineSection> sections) {
    final field = _visibleSectionField;

    if (field == null) {
      return null;
    }

    for (final section in sections) {
      if (section.fieldName == field) {
        return section.label;
      }
    }

    return null;
  }

  // =========================================================================
  // SECTION NAVIGATION
  // =========================================================================

  void _navigateToSection(
    ReadGuidelineController controller,
    GuidelineSection section,
  ) {
    controller.selectSection(section);

    setState(() {
      _visibleSectionField = section.fieldName;
    });

    final sectionContext = _sectionKey(section).currentContext;

    if (sectionContext == null) {
      return;
    }

    Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  GlobalKey _sectionKey(GuidelineSection section) {
    return _sectionKeys.putIfAbsent(section.fieldName, GlobalKey.new);
  }

  // =========================================================================
  // BOOKMARK
  // =========================================================================

  Future<void> _toggleBookmark(
    ReadGuidelineController controller,
    bool wasBookmarked,
  ) async {
    final success = await controller.toggleBookmark();

    if (!mounted) {
      return;
    }

    final navigatorContext = AppKeys.navigatorKey.currentContext;

    if (navigatorContext == null || !navigatorContext.mounted) {
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

  // =========================================================================
  // AI CONTEXT
  // =========================================================================

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

// ===========================================================================
// SECTION NAVIGATION
// ===========================================================================
