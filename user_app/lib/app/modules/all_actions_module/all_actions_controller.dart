import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';

import '../../data/services/backend_api_service.dart';
import '../../models/generic_page.dart';
import '../../routes/app_pages.dart';
import '../../translations/app_translations.dart';
import '../../utils/common.dart';

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

class AllActionsController extends GetxController {
  final RxList<AppAction> actions = <AppAction>[].obs;

  final RxList<GenericPage> genericPages = <GenericPage>[].obs;
  final RxBool isLoadingPages = false.obs;

  @override
  void onInit() {
    super.onInit();

    _loadStaticActions();
    loadGenericPages();
  }

  // =========================
  // STATIC ACTIONS
  // =========================

  void _loadStaticActions() {
    actions.assignAll([
      AppAction(
        id: 'essential_medicines',
        title: 'Essential Medicines',
        subtitle: 'WHO essential medicines reference',
        icon: LucideIcons.pill,
        color: Colors.blue,
        category: ActionCategory.clinicalTools,
        onTap: () => Get.toNamed(AppRoutes.drugIndex),
      ),

      AppAction(
        id: 'clinical_algorithms',
        title: 'Clinical Care Algorithms',
        subtitle: 'Clinical decision support tools',
        icon: LucideIcons.fileText,
        color: Colors.teal,
        category: ActionCategory.clinicalTools,
        onTap: () {
          Get.toNamed(AppRoutes.tools, arguments: {'initialTab': 2});
        },
      ),

      AppAction(
        id: 'ai_assistant',
        title: AppTranslationKey.aiChatAssistant,
        subtitle: AppTranslationKey.getInstantMedicalAssistance,
        icon: LucideIcons.bot,
        color: Colors.deepPurple,
        category: ActionCategory.aiAndReference,
        onTap: () => Get.toNamed(AppRoutes.aiAssistant),
      ),

      AppAction(
        id: 'abbreviations',
        title: AppTranslationKey.medicalAbbreviations,
        subtitle: AppTranslationKey.lookupMedicalTerms,
        icon: LucideIcons.bookText,
        color: Colors.indigo,
        category: ActionCategory.aiAndReference,
        onTap: () => Get.toNamed(AppRoutes.abbreviations),
      ),

      AppAction(
        id: 'guidelines',
        title: 'Clinical Guidelines',
        subtitle: 'Access medical guidelines',
        icon: LucideIcons.bookOpen,
        color: Colors.green,
        category: ActionCategory.clinicalTools,
        onTap: () => Get.toNamed(AppRoutes.guidelines),
      ),
    ]);
  }

  // =========================
  // DYNAMIC PAGES
  // =========================

  Future<void> loadGenericPages() async {
    try {
      isLoadingPages.value = true;

      final records = await BackendApiService.to.getResourceList(
        collectionName: 'generic_pages',
        perPage: 50,
      );

      final pages = records.items
          .map((record) => GenericPage.fromJson(record.toJson()))
          .toList();

      genericPages.assignAll(pages);
    } catch (e) {
      Common.quickToast(
        title: 'Failed to load pages',
        description: 'Could not fetch additional pages.',
        type: ToastificationType.error,
      );
    } finally {
      isLoadingPages.value = false;
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
    Get.toNamed(AppRoutes.genericViewer, arguments: page);
  }

  Future<void> reloadData() async {
    await loadGenericPages();
  }
}
