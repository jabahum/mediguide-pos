import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/core/utils/loading.dart';
import 'package:user_app/core/utils/responsive.dart';
import 'package:user_app/shared/widgets/html_styles.dart';
import 'package:user_app/shared/widgets/ai_context_button.dart';
import 'package:user_app/features/ai_assistant/data/services/ai_context_service.dart';
import 'package:user_app/features/ai_assistant/data/models/ai_context.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/content/presentation/controllers/generic_viewer_controller.dart';
import 'package:user_app/features/content/presentation/widgets/generic_page_section.dart';

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
    final key = widget.pageKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(genericViewerControllerProvider)
            .initialize(pageArgument: argument, pageKey: key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(genericViewerControllerProvider);
    final contextService = ref.watch(aiContextServiceProvider);
    return controller.isLoading
        ? const Scaffold(body: CenteredLoading(loading: Loading.large()))
        : !controller.hasContent
        ? Scaffold(
            appBar: AppBar(
              title: Text(
                controller.pageTitle,
                style: context.textTheme.titleMedium,
              ),
            ),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 64,
                      color: context.theme.colorScheme.onSurfaceVariant,
                    ),
                    AppSpacing.lg.gap,
                    Text(
                      'No Content Available',
                      style: context.textTheme.headlineSmall?.copyWith(
                        color: context.theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.md.gap,
                    Text(
                      'This page does not have any content to display.',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        : controller.isKeyValueContent
        ? DefaultTabController(
            length: controller.availableSections.length,
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  controller.pageTitle,
                  style: context.textTheme.titleMedium,
                ),
                actions: [
                  AiContextButton.iconButton(
                    context: _buildPageContext(controller, contextService),
                  ),
                  IconButton(
                    onPressed: controller.sharePage,
                    icon: const Icon(LucideIcons.share),
                    tooltip: 'Share',
                  ),
                ],
                bottom: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: controller.availableSections
                      .map((section) => Tab(text: section.title))
                      .toList(),
                  onTap: (index) {
                    controller.navigateToSection(
                      controller.availableSections[index],
                    );
                  },
                ),
              ),
              body: ListView(
                controller: controller.scrollController,
                padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                children: [
                  if (controller.page?.description != null) ...[
                    Text(
                      controller.page!.description!,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    AppSpacing.lg.gap,
                  ],
                  ...controller.availableSections.map(
                    (section) => GenericPageSectionWidget(
                      key: controller.getSectionKey(section),
                      section: section,
                    ),
                  ),
                  AppSpacing.xxl.gap,
                ],
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(
                controller.pageTitle,
                style: context.textTheme.titleMedium,
              ),
              actions: [
                AiContextButton.iconButton(
                  context: _buildPageContext(controller, contextService),
                ),
                IconButton(
                  onPressed: controller.sharePage,
                  icon: const Icon(LucideIcons.share),
                  tooltip: 'Share',
                ),
              ],
            ),
            body: ListView(
              padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
              children: [
                if (controller.page?.description != null) ...[
                  Text(
                    controller.page!.description!,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  AppSpacing.lg.gap,
                ],
                Html(
                  data: controller.stringContent,
                  style: HtmlStyles.content(context),
                ),
                AppSpacing.xxl.gap,
              ],
            ),
          );
  }

  /// Build AI context from current page data
  AiContext _buildPageContext(
    GenericViewerController controller,
    AiContextService contextService,
  ) {
    if (controller.page == null) {
      return QuickAiContext.genericPage(
        title: controller.pageTitle,
        content: 'No content available',
      );
    }

    final page = controller.page!;
    final content = controller.isKeyValueContent
        ? contextService.cleanHtmlContent(
            controller.availableSections
                .map((s) => '${s.title}: ${s.content}')
                .join('\n\n'),
          )
        : contextService.cleanHtmlContent(controller.stringContent);

    return contextService.extractGenericPageContext(
      title: page.title,
      content: content,
      description: page.description,
      pageId: page.id,
    );
  }
}
