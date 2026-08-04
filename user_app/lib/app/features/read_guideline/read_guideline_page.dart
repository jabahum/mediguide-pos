import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';

import '../../data/models/ai_context.dart';
import '../../data/models/models.dart';
import '../../features/guidelines/read_guideline_controller.dart';
import '../../core/di/core_providers.dart';
import '../../utils/app_spacing.dart';
import '../../utils/common.dart';
import '../../utils/loading.dart';
import '../../utils/responsive.dart';
import '../../widgets/ai_context_button.dart';
import 'widgets/guideline_header.dart';
import 'widgets/guideline_section.dart';

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

  ReadGuidelineRequest _resolveRequest() {
    final arguments = widget.arguments;
    if (arguments is Guideline) {
      return ReadGuidelineRequest(id: arguments.id, guideline: arguments);
    }
    if (arguments is Map) {
      final id =
          arguments['guidelineId']?.toString() ??
          arguments['id']?.toString() ??
          '';
      return ReadGuidelineRequest(id: id);
    }
    return ReadGuidelineRequest(id: arguments?.toString() ?? '');
  }

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

  void _trackScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    final progress = (_scrollController.position.pixels / max).clamp(0.0, 1.0);
    final controller = ref.read(
      readGuidelineControllerProvider(_request).notifier,
    );
    controller.setProgress(progress);
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 2), controller.saveProgress);
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    final asyncState = ref.watch(readGuidelineControllerProvider(request));
    return asyncState.when(
      loading: () =>
          const Scaffold(body: CenteredLoading(loading: Loading.large())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: AppSpacing.hPaddingMd,
            child: Text(
              request.id.isEmpty
                  ? 'No guideline was selected.'
                  : 'Unable to load this guideline. Please try again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (state) => _buildReader(context, request, state),
    );
  }

  Widget _buildReader(
    BuildContext context,
    ReadGuidelineRequest request,
    ReadGuidelineState state,
  ) {
    final controller = ref.read(
      readGuidelineControllerProvider(request).notifier,
    );
    return DefaultTabController(
      length: state.sections.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            state.guideline.conditionName,
            style: context.textTheme.titleMedium,
          ),
          actions: [
            AiContextButton.iconButton(context: _guidelineContext(state)),
            IconButton(
              onPressed: state.isMutating
                  ? null
                  : () => _toggleBookmark(controller, state.isBookmarked),
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
          bottom: state.sections.isEmpty
              ? null
              : TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: state.sections
                      .map((section) => Tab(text: section.label))
                      .toList(),
                  onTap: (index) {
                    final section = state.sections[index];
                    controller.selectSection(section);
                    final context = _sectionKey(section).currentContext;
                    if (context != null) {
                      Scrollable.ensureVisible(
                        context,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GuidelineHeader(guideline: state.guideline),
              AppSpacing.contentGap,
              ...state.sections.map(
                (section) => GuidelineSectionWidget(
                  key: _sectionKey(section),
                  section: section,
                  content: guidelineSectionContent(state.guideline, section),
                ),
              ),
              AppSpacing.xxl.gap,
            ],
          ),
        ),
      ),
    );
  }

  GlobalKey _sectionKey(GuidelineSection section) =>
      _sectionKeys.putIfAbsent(section.fieldName, GlobalKey.new);

  Future<void> _toggleBookmark(
    ReadGuidelineController controller,
    bool wasBookmarked,
  ) async {
    final success = await controller.toggleBookmark();
    if (!mounted) return;
    if (success) {
      Common.quickToast(
        title: wasBookmarked ? 'Bookmark removed' : 'Guideline bookmarked',
      );
    } else {
      Common.quickToast(
        title: 'Failed to update bookmark',
        type: ToastificationType.error,
      );
    }
  }

  AiContext _guidelineContext(ReadGuidelineState state) {
    final contents = <String, dynamic>{
      for (final section in state.sections)
        if (guidelineSectionContent(state.guideline, section).isNotEmpty)
          section.label: guidelineSectionContent(state.guideline, section),
    };
    return ref
        .read(aiContextServiceProvider)
        .extractGuidelineContext(
          conditionName: state.guideline.conditionName,
          guidelineData: contents,
          guidelineId: state.guideline.id,
        );
  }
}
