import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/content/data/models/generic_page.dart';
import 'package:user_app/features/content/data/repositories/content_reference_repository.dart';

import 'package:user_app/l10n/app_translations.dart';

part 'all_actions_controller.g.dart';

enum ActionCategory {
  clinicalTools,
  aiAndReference,
  healthServices,
  additionalContent,
}

class AppAction {
  const AppAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.category,
    this.enabled = true,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final ActionCategory category;
  final bool enabled;
}

class AllActionsState {
  const AllActionsState({
    this.actions = const [],
    this.genericPages = const [],
    this.isLoadingPages = false,
    this.errorMessage,
  });

  final List<AppAction> actions;
  final List<GenericPage> genericPages;
  final bool isLoadingPages;
  final String? errorMessage;

  AllActionsState copyWith({
    List<AppAction>? actions,
    List<GenericPage>? genericPages,
    bool? isLoadingPages,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AllActionsState(
      actions: actions ?? this.actions,
      genericPages: genericPages ?? this.genericPages,
      isLoadingPages: isLoadingPages ?? this.isLoadingPages,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

@riverpod
class AllActionsController extends _$AllActionsController {
  GenericPageRepository get _repository =>
      ref.read(genericPageRepositoryProvider);

  @override
  AllActionsState build() {
    final initialState = AllActionsState(actions: _buildStaticActions());

    Future.microtask(loadGenericPages);

    return initialState;
  }

  // =========================
  // STATIC ACTIONS
  // =========================

  List<AppAction> _buildStaticActions() {
    return [
      AppAction(
        id: 'essential_medicines',
        title: 'Essential Medicines',
        subtitle: 'WHO essential medicines reference',
        icon: LucideIcons.pill,
        color: Colors.blue,
        category: ActionCategory.clinicalTools,
        onTap: () {
          AppNavigator.push(AppRoutes.drugIndex);
        },
      ),
      AppAction(
        id: 'clinical_algorithms',
        title: 'Clinical Care Algorithms',
        subtitle: 'Clinical decision support tools',
        icon: LucideIcons.fileText,
        color: Colors.teal,
        category: ActionCategory.clinicalTools,
        onTap: () {
          AppNavigator.push(AppRoutes.tools, extra: {'initialTab': 2});
        },
      ),
      AppAction(
        id: 'ai_assistant',
        title: AppTranslationKey.aiChatAssistant,
        subtitle: AppTranslationKey.getInstantMedicalAssistance,
        icon: LucideIcons.bot,
        color: Colors.deepPurple,
        category: ActionCategory.aiAndReference,
        onTap: () {
          AppNavigator.push(AppRoutes.aiAssistant);
        },
      ),
      AppAction(
        id: 'abbreviations',
        title: AppTranslationKey.medicalAbbreviations,
        subtitle: AppTranslationKey.lookupMedicalTerms,
        icon: LucideIcons.bookText,
        color: Colors.indigo,
        category: ActionCategory.aiAndReference,
        onTap: () {
          AppNavigator.push(AppRoutes.abbreviations);
        },
      ),
      AppAction(
        id: 'guidelines',
        title: 'Clinical Guidelines',
        subtitle: 'Access medical guidelines',
        icon: LucideIcons.bookOpen,
        color: Colors.green,
        category: ActionCategory.clinicalTools,
        onTap: () {
          AppNavigator.push(AppRoutes.publicGuidelines);
        },
      ),
    ];
  }

  // =========================
  // DYNAMIC PAGES
  // =========================

  Future<void> loadGenericPages() async {
    state = state.copyWith(isLoadingPages: true, clearErrorMessage: true);

    try {
      final result = await _repository.list(perPage: 50);

      state = state.copyWith(genericPages: result.items);
    } catch (error) {
      final message = 'errorLoadingPages'.tr;

      state = state.copyWith(errorMessage: message);

      final context = AppKeys.navigatorKey.currentContext;

      if (context != null && context.mounted) {
        AppMessage.error(context, message);
      }
    } finally {
      state = state.copyWith(isLoadingPages: false);
    }
  }

  // =========================
  // HELPERS
  // =========================

  List<AppAction> actionsByCategory(ActionCategory category) {
    return state.actions
        .where((action) => action.category == category && action.enabled)
        .toList(growable: false);
  }

  void openGenericPage(GenericPage page) {
    AppNavigator.push(AppRoutes.genericViewer, extra: page);
  }

  Future<void> reloadData() async {
    await loadGenericPages();
  }
}
