// generic_viewer_controller.dart

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/content/data/models/generic_page.dart';
import 'package:user_app/features/content/data/repositories/content_reference_repository.dart';
import 'package:user_app/features/content/presentation/controllers/generic_viewer_state.dart';

part 'generic_viewer_controller.g.dart';

@riverpod
class GenericViewerController extends _$GenericViewerController {
  late final ScrollController scrollController;

  final Map<String, GlobalKey> sectionKeys = {};

  GenericPageRepository get _repository =>
      ref.read(genericPageRepositoryProvider);

  @override
  GenericViewerState build() {
    scrollController = ScrollController();

    ref.onDispose(() {
      scrollController.dispose();
      sectionKeys.clear();
    });

    return const GenericViewerState();
  }

  // ======================================================
  // INITIALIZATION
  // ======================================================

  Future<void> initialize({Object? pageArgument, String? pageKey}) async {
    if (pageArgument is GenericPage) {
      _setPage(pageArgument);
      return;
    }

    final key = pageKey ?? pageArgument?.toString().trim();

    if (key != null && key.isNotEmpty) {
      await loadPage(key);
      return;
    }

    state = state.copyWith(isLoading: false);
  }

  // ======================================================
  // LOAD PAGE
  // ======================================================

  Future<void> loadPage(String pageKey) async {
    final key = pageKey.trim();

    if (key.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final page = await _repository.byKey(key);

      _setPage(page);
    } catch (error) {
      final message = error.toString();

      state = state.copyWith(isLoading: false, errorMessage: message);

      _showError(message);
    }
  }

  // ======================================================
  // PAGE / SECTION SETUP
  // ======================================================

  void _setPage(GenericPage page) {
    final sections = page.isKeyValueContent
        ? List<GenericPageSection>.unmodifiable(page.sections)
        : const <GenericPageSection>[];

    final currentSection = sections.isNotEmpty ? sections.first.key : '';

    sectionKeys.clear();

    state = state.copyWith(
      page: page,
      isLoading: false,
      availableSections: sections,
      currentSection: currentSection,
      clearErrorMessage: true,
    );
  }

  // ======================================================
  // SECTION NAVIGATION
  // ======================================================

  Future<void> navigateToSection(GenericPageSection section) async {
    state = state.copyWith(currentSection: section.key);

    final key = sectionKeys[section.key];
    final context = key?.currentContext;

    if (context == null) {
      return;
    }

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  GlobalKey getSectionKey(GenericPageSection section) {
    return sectionKeys.putIfAbsent(section.key, GlobalKey.new);
  }

  // ======================================================
  // REFRESH
  // ======================================================

  Future<void> reload() async {
    final page = state.page;

    if (page == null) {
      return;
    }

    final key = page.key;

    if (key.isEmpty) {
      return;
    }

    await loadPage(key);
  }

  // ======================================================
  // SHARE
  // ======================================================

  void sharePage() {
    final page = state.page;

    if (page == null) {
      return;
    }

    final context = AppKeys.navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    AppMessage.info(context, 'Sharing page: ${page.title}');

    // TODO:
    // Replace this with share_plus when actual
    // sharing is implemented.
  }

  // ======================================================
  // ERROR
  // ======================================================

  void _showError(String message) {
    final context = AppKeys.navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    AppMessage.error(context, message);
  }
}
