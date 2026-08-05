import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';

import 'package:user_app/features/content/data/repositories/content_reference_repository.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/content/data/models/generic_page.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/l10n/app_translations.dart';
import 'package:user_app/core/utils/common.dart';

enum ActionCategory {
  clinicalTools,
  aiAndReference,
  healthServices,
  additionalContent,
}

class AppAction {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final ActionCategory category;
  final bool enabled;

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
}

final allActionsControllerProvider = ChangeNotifierProvider.autoDispose(
  (ref) => AllActionsController(ref.watch(genericPageRepositoryProvider)),
);

class AllActionsController extends ChangeNotifier {
  AllActionsController(this._repository) {
    _loadStaticActions();
    loadGenericPages();
  }

  final GenericPageRepository _repository;
  List<AppAction> actions = [];
  List<GenericPage> genericPages = [];
  bool isLoadingPages = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // =========================
  // STATIC ACTIONS
  // =========================

  void _loadStaticActions() {
    actions = [
      AppAction(
        id: 'essential_medicines',
        title: 'Essential Medicines',
        subtitle: 'WHO essential medicines reference',
        icon: LucideIcons.pill,
        color: Colors.blue,
        category: ActionCategory.clinicalTools,
        onTap: () => AppNavigator.pushNamed(AppRoutes.drugIndex),
      ),

      AppAction(
        id: 'clinical_algorithms',
        title: 'Clinical Care Algorithms',
        subtitle: 'Clinical decision support tools',
        icon: LucideIcons.fileText,
        color: Colors.teal,
        category: ActionCategory.clinicalTools,
        onTap: () {
          AppNavigator.pushNamed(AppRoutes.tools, arguments: {'initialTab': 2});
        },
      ),

      AppAction(
        id: 'ai_assistant',
        title: AppTranslationKey.aiChatAssistant,
        subtitle: AppTranslationKey.getInstantMedicalAssistance,
        icon: LucideIcons.bot,
        color: Colors.deepPurple,
        category: ActionCategory.aiAndReference,
        onTap: () => AppNavigator.pushNamed(AppRoutes.aiAssistant),
      ),

      AppAction(
        id: 'abbreviations',
        title: AppTranslationKey.medicalAbbreviations,
        subtitle: AppTranslationKey.lookupMedicalTerms,
        icon: LucideIcons.bookText,
        color: Colors.indigo,
        category: ActionCategory.aiAndReference,
        onTap: () => AppNavigator.pushNamed(AppRoutes.abbreviations),
      ),

      AppAction(
        id: 'guidelines',
        title: 'Clinical Guidelines',
        subtitle: 'Access medical guidelines',
        icon: LucideIcons.bookOpen,
        color: Colors.green,
        category: ActionCategory.clinicalTools,
        onTap: () => AppNavigator.pushNamed(AppRoutes.guidelines),
      ),
    ];
  }

  // =========================
  // DYNAMIC PAGES
  // =========================

  Future<void> loadGenericPages() async {
    try {
      isLoadingPages = true;
      _notify();

      final result = await _repository.list(perPage: 50);
      genericPages = result.items;
    } catch (e) {
      Common.quickToast(
        title: 'Failed to load pages',
        description: 'Could not fetch additional pages.',
        type: ToastificationType.error,
      );
    } finally {
      isLoadingPages = false;
      _notify();
    }
  }

  // =========================
  // HELPERS
  // =========================

  List<AppAction> actionsByCategory(ActionCategory category) {
    return actions
        .where((action) => action.category == category && action.enabled)
        .toList();
  }

  void openGenericPage(GenericPage page) {
    AppNavigator.pushNamed(AppRoutes.genericViewer, arguments: page);
  }

  Future<void> reloadData() async {
    await loadGenericPages();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
