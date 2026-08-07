// generic_viewer_state.dart

import 'package:user_app/features/content/data/models/generic_page.dart';

final class GenericViewerState {
  const GenericViewerState({
    this.page,
    this.isLoading = true,
    this.currentSection = '',
    this.availableSections = const [],
    this.errorMessage,
  });

  final GenericPage? page;
  final bool isLoading;
  final String currentSection;
  final List<GenericPageSection> availableSections;
  final String? errorMessage;

  bool get hasContent => page?.hasContent == true;

  String get pageTitle => page?.title ?? 'Page';

  bool get isStringContent => page?.isStringContent == true;

  bool get isKeyValueContent => page?.isKeyValueContent == true;

  String get stringContent => page?.stringContent ?? '';

  GenericViewerState copyWith({
    GenericPage? page,
    bool clearPage = false,
    bool? isLoading,
    String? currentSection,
    List<GenericPageSection>? availableSections,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return GenericViewerState(
      page: clearPage ? null : page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      currentSection: currentSection ?? this.currentSection,
      availableSections: availableSections ?? this.availableSections,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
