import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import '../../data/services/backend_api_service.dart';
import '../../data/repositories/content_reference_repository.dart';
import '../../models/generic_page.dart';
import '../../utils/common.dart';

class GenericViewerController extends GetxController {
  // Observable state
  final Rx<GenericPage?> page = Rx<GenericPage?>(null);
  final RxBool isLoading = true.obs;
  final RxString currentSection = ''.obs;
  final RxList<GenericPageSection> availableSections =
      <GenericPageSection>[].obs;

  // Scroll controller for section navigation
  final ScrollController scrollController = ScrollController();

  // Section keys for scroll-to functionality
  final Map<String, GlobalKey> sectionKeys = {};

  @override
  void onInit() {
    super.onInit();

    // Check if GenericPage model was passed as argument (preferred)
    final pageArgument = Get.arguments;
    if (pageArgument is GenericPage) {
      page.value = pageArgument;
      _setupSections();
      isLoading.value = false;
      return;
    }

    // Fallback to loading by key for backward compatibility
    final pageKey = Get.parameters['key'] ?? pageArgument;
    if (pageKey != null) {
      loadPage(pageKey);
    } else {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// Load page data from backend resource API using page key
  Future<void> loadPage(String pageKey) async {
    try {
      isLoading.value = true;

      page.value = await GenericPageRepository(
        BackendApiService.to,
      ).byKey(pageKey);
      _setupSections();
    } catch (e) {
      Common.quickToast(
        title: 'Failed to load page',
        description: 'Please check your connection and try again.',
        type: ToastificationType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Setup sections for key-value content
  void _setupSections() {
    if (page.value?.isKeyValueContent == true) {
      availableSections.assignAll(page.value!.sections);
      if (availableSections.isNotEmpty) {
        currentSection.value = availableSections.first.key;
      }
    }
  }

  /// Navigate to a specific section (scroll to it)
  void navigateToSection(GenericPageSection section) {
    currentSection.value = section.key;

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
  bool get hasContent => page.value?.hasContent == true;

  /// Get page title for app bar
  String get pageTitle => page.value?.title ?? 'Page';

  /// Check if content is string type
  bool get isStringContent => page.value?.isStringContent == true;

  /// Check if content is key-value type
  bool get isKeyValueContent => page.value?.isKeyValueContent == true;

  /// Get string content for HTML display
  String get stringContent => page.value?.stringContent ?? '';

  /// Share the current page
  void sharePage() {
    if (page.value == null) return;

    Common.quickToast(
      title: 'Share feature',
      description: 'Sharing ${page.value!.title}...',
    );
    // TODO: Implement actual share functionality
  }
}
