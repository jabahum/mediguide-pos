import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'package:user_app/features/content/data/repositories/content_reference_repository.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/content/data/models/generic_page.dart';
import 'package:user_app/core/utils/common.dart';

final genericViewerControllerProvider = ChangeNotifierProvider.autoDispose(
  (ref) => GenericViewerController(ref.watch(genericPageRepositoryProvider)),
);

class GenericViewerController extends ChangeNotifier {
  GenericViewerController(this._repository);
  final GenericPageRepository _repository;
  GenericPage? page;
  bool isLoading = true;
  String currentSection = '';
  List<GenericPageSection> availableSections = [];
  bool _disposed = false;

  // Scroll controller for section navigation
  final ScrollController scrollController = ScrollController();

  // Section keys for scroll-to functionality
  final Map<String, GlobalKey> sectionKeys = {};

  Future<void> initialize({Object? pageArgument, String? pageKey}) async {
    if (pageArgument is GenericPage) {
      page = pageArgument;
      _setupSections();
      isLoading = false;
      _notify();
      return;
    }
    final key = pageKey ?? pageArgument?.toString();
    if (key != null && key.isNotEmpty) {
      await loadPage(key);
    } else {
      isLoading = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    scrollController.dispose();
    super.dispose();
  }

  /// Load page data from backend resource API using page key
  Future<void> loadPage(String pageKey) async {
    try {
      isLoading = true;
      _notify();

      page = await _repository.byKey(pageKey);
      _setupSections();
    } catch (e) {
      Common.quickToast(
        title: 'Failed to load page',
        description: 'Please check your connection and try again.',
        type: ToastificationType.error,
      );
    } finally {
      isLoading = false;
      _notify();
    }
  }

  /// Setup sections for key-value content
  void _setupSections() {
    if (page?.isKeyValueContent == true) {
      availableSections = page!.sections;
      if (availableSections.isNotEmpty) {
        currentSection = availableSections.first.key;
      }
    }
  }

  /// Navigate to a specific section (scroll to it)
  void navigateToSection(GenericPageSection section) {
    currentSection = section.key;
    _notify();

    final key = sectionKeys[section.key];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Get or create section key for scroll-to functionality
  GlobalKey getSectionKey(GenericPageSection section) {
    if (!sectionKeys.containsKey(section.key)) {
      sectionKeys[section.key] = GlobalKey();
    }
    return sectionKeys[section.key]!;
  }

  /// Check if page has content to display
  bool get hasContent => page?.hasContent == true;

  /// Get page title for app bar
  String get pageTitle => page?.title ?? 'Page';

  /// Check if content is string type
  bool get isStringContent => page?.isStringContent == true;

  /// Check if content is key-value type
  bool get isKeyValueContent => page?.isKeyValueContent == true;

  /// Get string content for HTML display
  String get stringContent => page?.stringContent ?? '';

  /// Share the current page
  void sharePage() {
    if (page == null) return;

    Common.quickToast(
      title: 'Share feature',
      description: 'Sharing ${page!.title}...',
    );
    // TODO: Implement actual share functionality
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
