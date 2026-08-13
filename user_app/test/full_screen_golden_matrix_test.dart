import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:user_app/app/theme/app_theme.dart';
import 'package:user_app/features/ai_assistant/presentation/controllers/ai_assistant_controller.dart';
import 'package:user_app/features/ai_assistant/presentation/screens/ai_assistant_page.dart';
import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/features/authentication/data/models/user_enums.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_state.dart';
import 'package:user_app/features/authentication/presentation/controllers/biometric_controller.dart';
import 'package:user_app/features/authentication/presentation/screens/onboarding_page.dart';
import 'package:user_app/features/calculators/data/models/calculator.dart';
import 'package:user_app/features/calculators/presentation/controllers/tools_controller.dart';
import 'package:user_app/features/calculators/presentation/controllers/tools_state.dart';
import 'package:user_app/features/calculators/presentation/screens/tools_page.dart';
import 'package:user_app/features/downloads/data/models/offline_download.dart';
import 'package:user_app/features/downloads/presentation/controllers/guideline_downloads_controller.dart';
import 'package:user_app/features/downloads/presentation/screens/offline_content_page.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/guidelines/data/models/reading_progress.dart';
import 'package:user_app/features/guidelines/presentation/controllers/publication_guideline_controller.dart';
import 'package:user_app/features/guidelines/presentation/screens/publication_clinical_viewers.dart';
import 'package:user_app/features/guidelines/presentation/screens/publication_guideline_page.dart';
import 'package:user_app/features/home/presentation/controllers/home_controller.dart';
import 'package:user_app/features/home/presentation/controllers/home_state.dart';
import 'package:user_app/features/home/presentation/screens/guest_home_page.dart';
import 'package:user_app/features/home/presentation/screens/home_page.dart';
import 'package:user_app/features/library/data/models/guideline_library_models.dart';
import 'package:user_app/features/library/presentation/screens/my_library_page.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/features/outbreaks/presentation/screens/outbreak_screens.dart';
import 'package:user_app/features/profile/presentation/screens/profile_page.dart';
import 'package:user_app/features/search/presentation/screens/global_search_page.dart';
import 'package:user_app/features/settings/presentation/controllers/app_update_controller.dart';
import 'package:user_app/features/settings/presentation/controllers/language_controller.dart';

final class _GoldenAuthController extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.authenticated(
    User(
      id: 'golden-user',
      name: 'Dr. Sarah Nakato',
      email: 'sarah@example.test',
      organization: 'Gulu Regional Referral Hospital',
      jobTitle: 'Clinical Officer',
      role: UserRole.healthcareProvider,
    ),
  );
}

final class _GoldenHomeController extends HomeController {
  @override
  Future<HomeState> build() async => HomeState(
    continueReadingItems: [
      ReadingProgress(
        id: 'progress-1',
        userId: 'golden-user',
        guidelineId: 'golden-guideline',
        currentSection: 'assessment',
        totalSections: 4,
        progressPercentage: .65,
        lastReadAtValue: DateTime.utc(2026, 7, 26),
      ),
    ],
    recentlyUpdatedGuidelines: const [_publication],
    pinnedGuidelines: const [_publication],
    unreadMessagesCount: 3,
  );
}

final class _GoldenDownloadsController extends GuidelineDownloadsController {
  @override
  Future<List<OfflineDownload>> build() async => [
    OfflineDownload(
      id: 'download-1',
      guidelineId: 'golden-guideline',
      assetType: 'offline_package',
      title: _publication.title,
      version: '1.4',
      checksum: 'verified',
      sizeBytes: 2400000,
      status: OfflineDownloadStatus.ready,
      progress: 1,
      localPath: '/documents/guideline.zip',
      scope: 'user:golden-user',
    ),
  ];
}

final class _GoldenToolsController extends ToolsController {
  @override
  ToolsState build(Object? arguments) {
    pagingController = PagingController<int, Calculator>(
      getNextPageKey: (_) => null,
      fetchPage: (_) async => const <Calculator>[],
    );
    ref.onDispose(pagingController.dispose);
    return const ToolsState();
  }
}

final class _GoldenBiometricController extends BiometricController {
  @override
  Future<BiometricState> build() async =>
      const BiometricState(available: true, enabled: false);
}

final class _GoldenLanguageController extends LanguageController {
  @override
  Future<LanguageState> build() async =>
      const LanguageState(languages: [], currentCode: 'en');
}

final class _GoldenUpdateController extends AppUpdateController {
  @override
  Future<AppUpdateResult?> build() async => AppUpdateResult.upToDate;
}

final class _GoldenAiController extends AiAssistantController {
  @override
  AiAssistantState build(initialContext) {
    currentUser = ChatUser(id: 'golden-user', firstName: 'Sarah');
    aiUser = ChatUser(id: 'ai', firstName: 'MediGuide AI');
    chatController = ChatMessagesController();
    ref.onDispose(chatController.dispose);
    return const AiAssistantState(
      contextualWelcomeMessage:
          'Ask a clinical question and review the cited guideline evidence.',
      contextualExampleQuestions: [
        'What are the danger signs?',
        'Show the recommended assessment steps.',
      ],
    );
  }
}

const _publication = GuidelinePublication(
  id: 'golden-guideline',
  title: 'Malaria diagnosis and treatment',
  description: 'Evidence-based recommendations for adult malaria care.',
  country: 'Uganda',
  sourceOrganization: 'Ministry of Health Uganda',
  programArea: 'Malaria',
  language: 'English',
  publicationDate: '26 July 2026',
  reviewDate: '26 July 2027',
  version: '1.4',
  intendedPopulation: 'Adults and adolescents',
  healthcareLevel: 'All levels',
);

GuidelinePublicationContent _content(
  GuidelineReaderMode mode,
) => GuidelinePublicationContent(
  publication: _publication,
  manifest: GuidelineManifest(
    guidelineId: _publication.id,
    versionId: 'version-1',
    version: '1.4',
    extractionQuality: mode == GuidelineReaderMode.structured
        ? 'reviewed'
        : 'partial',
    recommendedMode: mode,
    hasChapters: mode != GuidelineReaderMode.originalDocument,
    hasKeyPoints: mode == GuidelineReaderMode.structured,
    hasTables: mode == GuidelineReaderMode.structured,
    hasAlgorithms: mode == GuidelineReaderMode.structured,
    hasOriginalPdf: true,
    hasOfflinePackage: true,
    sectionCount: 2,
    blockCount: 4,
    tableCount: 1,
    algorithmCount: 1,
  ),
  sections: const [
    PublicationSection(
      id: 'assessment',
      title: 'Diagnosis and assessment',
      level: 1,
      pageStart: 12,
      sortOrder: 1,
    ),
    PublicationSection(
      id: 'treatment',
      title: 'Treatment',
      level: 1,
      pageStart: 18,
      sortOrder: 2,
    ),
  ],
  blocks: const [
    GuidelineBlock.heading(
      id: 'heading-1',
      sectionId: 'assessment',
      sortOrder: 1,
      text: 'Diagnostic assessment',
      level: 2,
      pageStart: 12,
    ),
    GuidelineBlock.paragraph(
      id: 'paragraph-1',
      sectionId: 'assessment',
      sortOrder: 2,
      text:
          'Assess the patient, identify danger signs and confirm the diagnosis using the reviewed source guidance.',
      pageStart: 12,
    ),
    GuidelineBlock.table(
      id: 'table-1',
      sectionId: 'assessment',
      sortOrder: 3,
      payload: GuidelineTablePayload(
        title: 'Diagnostic test performance',
        columns: ['Test', 'Sensitivity', 'Specificity'],
        rows: [
          ['RDT', '95–98%', '97–99%'],
          ['Microscopy', '90–96%', '96–98%'],
        ],
        footnotes: ['Use the current approved test algorithm.'],
      ),
      pageStart: 13,
    ),
    GuidelineBlock.algorithm(
      id: 'algorithm-1',
      sectionId: 'treatment',
      sortOrder: 1,
      payload: GuidelineAlgorithmPayload(
        title: 'Initial assessment pathway',
        nodes: [
          GuidelineAlgorithmNode(
            id: 'start',
            label: 'Assess danger signs',
            kind: 'start',
            next: ['confirm'],
          ),
          GuidelineAlgorithmNode(
            id: 'confirm',
            label: 'Confirm diagnosis',
            kind: 'action',
          ),
        ],
      ),
      pageStart: 18,
    ),
  ],
);

final _outbreak = PublicOutbreak(
  id: 'outbreak-1',
  title: 'Bundibugyo virus disease response',
  diseaseType: 'Bundibugyo virus disease',
  status: 'monitoring',
  geographicArea: 'Uganda–DRC border region',
  summary:
      'Cross-border surveillance and preparedness remain active while the response continues.',
  lastUpdate: DateTime.utc(2026, 7, 26),
  visualTone: 'warning',
  sourceOrganization: 'Ministry of Health Uganda and WHO',
  metrics: const [
    OutbreakMetric(key: 'cases', label: 'Confirmed cases', value: '20'),
    OutbreakMetric(key: 'contacts', label: 'Contacts followed', value: '836'),
  ],
);

final _report = PublicSituationReport(
  id: 'report-1',
  outbreakId: 'outbreak-1',
  title: 'Weekly external situation report 11',
  geographicArea: 'Democratic Republic of the Congo and Uganda',
  summary: 'Published regional situation and preparedness update.',
  sourceOrganization: 'WHO Regional Office for Africa',
  publicationDate: DateTime.utc(2026, 7, 26),
  status: 'published',
  reportAssetUrl: 'https://example.test/report.pdf',
  keyHighlights: const [
    'Regional surveillance remains active.',
    'Cross-border preparedness continues.',
  ],
  metrics: const [
    OutbreakMetric(key: 'contacts', label: 'Contacts followed', value: '836'),
  ],
);

final class _Viewport {
  const _Viewport(this.name, this.size, this.scale, {this.dark = false});
  final String name;
  final Size size;
  final double scale;
  final bool dark;
}

final class _Scenario {
  const _Scenario(this.name, this.widget, {this.overrides = const []});
  final String name;
  final Widget widget;
  final List<Override> overrides;
}

void main() {
  final commonOverrides = <Override>[
    authControllerProvider.overrideWith(_GoldenAuthController.new),
    homeControllerProvider.overrideWith(_GoldenHomeController.new),
    guidelineDownloadsControllerProvider.overrideWith(
      _GoldenDownloadsController.new,
    ),
    biometricControllerProvider.overrideWith(_GoldenBiometricController.new),
    languageControllerProvider.overrideWith(_GoldenLanguageController.new),
    appUpdateControllerProvider.overrideWith(_GoldenUpdateController.new),
    aiAssistantControllerProvider(null).overrideWith(_GoldenAiController.new),
    toolsControllerProvider(null).overrideWith(_GoldenToolsController.new),
    guestHomePublicationsProvider.overrideWith((_) async => [_publication]),
    guestHomeOutbreaksProvider.overrideWith((_) async => [_outbreak]),
    publicOutbreaksProvider.overrideWith((_) async => [_outbreak]),
    publicSituationReportProvider(
      'report-1',
    ).overrideWith((_) async => _report),
    publicationReadingProgressProvider(
      'golden-guideline',
    ).overrideWith((_) async => null),
    guidelineOriginalDocumentProvider('golden-guideline').overrideWith(
      (_) async => const GuidelineAsset(
        id: 'pdf-1',
        type: 'original_pdf',
        mimeType: 'application/pdf',
        originalFilename: 'malaria-guideline.pdf',
        url: 'https://example.test/guideline.pdf',
        sizeBytes: 2400000,
        checksum: 'verified',
      ),
    ),
    libraryDataProvider.overrideWith(
      (_) async => LibraryData(
        bookmarks: [
          ReadingProgress(
            id: 'bookmark-1',
            guidelineId: 'golden-guideline',
            progressPercentage: .65,
            isBookmarked: true,
            lastReadAtValue: DateTime.utc(2026, 7, 26),
          ),
        ],
        history: const [],
        publications: const {'golden-guideline': _publication},
        collections: const [
          GuidelineCollectionSummary(
            id: 'collection-1',
            name: 'Emergency care',
            description: 'Rapid-access guidance',
            itemCount: 4,
          ),
        ],
        downloads: const [],
      ),
    ),
  ];

  final scenarios = <_Scenario>[
    const _Scenario('onboarding', OnboardingPage()),
    const _Scenario('guest_home', GuestHomePage()),
    const _Scenario('guest_search', GlobalSearchPage()),
    const _Scenario('outbreak_hub', OutbreakHubPage()),
    _Scenario(
      'guideline_overview',
      const PublicationGuidelinePage(guidelineId: 'golden-guideline'),
      overrides: [
        publicationGuidelineProvider(
          'golden-guideline',
        ).overrideWith((_) async => _content(GuidelineReaderMode.structured)),
      ],
    ),
    _Scenario(
      'structured_reader',
      const PublicationGuidelinePage(
        guidelineId: 'golden-guideline',
        readerOnly: true,
      ),
      overrides: [
        publicationGuidelineProvider(
          'golden-guideline',
        ).overrideWith((_) async => _content(GuidelineReaderMode.structured)),
      ],
    ),
    _Scenario(
      'partial_reader',
      const PublicationGuidelinePage(
        guidelineId: 'golden-guideline',
        readerOnly: true,
      ),
      overrides: [
        publicationGuidelineProvider(
          'golden-guideline',
        ).overrideWith((_) async => _content(GuidelineReaderMode.partial)),
      ],
    ),
    _Scenario(
      'original_document_reader',
      const PublicationGuidelinePage(
        guidelineId: 'golden-guideline',
        readerOnly: true,
      ),
      overrides: [
        publicationGuidelineProvider('golden-guideline').overrideWith(
          (_) async => _content(GuidelineReaderMode.originalDocument),
        ),
      ],
    ),
    const _Scenario('authenticated_home', HomePage(greetingHour: 9)),
    const _Scenario('my_library', MyLibraryPage()),
    const _Scenario('ai_assistant', AiAssistantPage()),
    const _Scenario('tools', ToolsPage()),
    const _Scenario('profile', ProfilePage()),
    _Scenario(
      'algorithm_viewer',
      const PublicationAlgorithmPage(
        guidelineId: 'golden-guideline',
        blockId: 'algorithm-1',
      ),
      overrides: [
        publicationGuidelineProvider(
          'golden-guideline',
        ).overrideWith((_) async => _content(GuidelineReaderMode.structured)),
      ],
    ),
    _Scenario(
      'table_viewer',
      const PublicationTablePage(
        guidelineId: 'golden-guideline',
        blockId: 'table-1',
      ),
      overrides: [
        publicationGuidelineProvider(
          'golden-guideline',
        ).overrideWith((_) async => _content(GuidelineReaderMode.structured)),
      ],
    ),
    const _Scenario('offline_content', OfflineContentPage()),
    const _Scenario(
      'situation_report_detail',
      SituationReportDetailPage(reportId: 'report-1'),
    ),
  ];

  const viewports = <_Viewport>[
    _Viewport('narrow_phone', Size(320, 720), 1),
    _Viewport('large_phone', Size(430, 932), 1),
    _Viewport('tablet', Size(800, 1280), 1),
    _Viewport('text_200', Size(390, 844), 2),
    _Viewport('dark_phone', Size(390, 844), 1, dark: true),
  ];

  for (final scenario in scenarios) {
    for (final viewport in viewports) {
      testWidgets('${scenario.name} — ${viewport.name}', (tester) async {
        tester.view.physicalSize = viewport.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = GoRouter(
          initialLocation: '/',
          routes: [GoRoute(path: '/', builder: (_, _) => scenario.widget)],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [...commonOverrides, ...scenario.overrides],
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: viewport.dark ? ThemeMode.dark : ThemeMode.light,
              routerConfig: router,
              builder: (context, child) => ResponsiveBreakpoints.builder(
                breakpoints: const [
                  Breakpoint(start: 0, end: 450, name: MOBILE),
                  Breakpoint(start: 451, end: 900, name: TABLET),
                  Breakpoint(start: 901, end: double.infinity, name: DESKTOP),
                ],
                child: MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(viewport.scale)),
                  child: child!,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason: exception is FlutterError
              ? exception.toStringDeep()
              : exception?.toString(),
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/full_screen/${scenario.name}_${viewport.name}.png',
          ),
        );
      });
    }
  }
}
