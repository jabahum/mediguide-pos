import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/models.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/backend_api_service.dart';
import '../../routes/app_pages.dart';
import './models/stats_model.dart';

class HomeController extends GetxController {
  // =========================
  // SERVICES
  // =========================
  AuthService get _authService => AuthService.to;
  BackendApiService get _apiService => BackendApiService.to;

  // =========================
  // GUIDELINE CONSTANTS
  // =========================
  static const String emergencyCategoryId = 'p4vdq6cqnb2mnin';

  // =========================
  // STATE
  // =========================
  final RxBool isLoading = false.obs;
  final RxBool isLoadingStats = false.obs;
  final RxBool isLoadingGuidelines = false.obs;

  final RxList<ReadingProgress> continueReadingItems = <ReadingProgress>[].obs;
  final RxList<Calculator> featuredCalculators = <Calculator>[].obs;
  final RxList<Guideline> pinnedGuidelines = <Guideline>[].obs;
  final RxList<Guideline> recentlyUpdatedGuidelines = <Guideline>[].obs;
  final RxList<GuidelineCategory> guidelineCategories =
      <GuidelineCategory>[].obs;

  final RxInt unreadMessagesCount = 0.obs;
  final RxMap<String, int> stats = <String, int>{}.obs;

  DateTime? _lastStatsFetch;

  // =========================
  // INIT
  // =========================
  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  // =========================
  // INITIAL LOAD
  // =========================
  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      await Future.wait([loadAllData(), fetchStats()]);
    } finally {
      isLoading.value = false;
    }
  }

  // =========================
  // REFRESH
  // =========================
  Future<void> refreshData() async {
    await Future.wait([loadAllData(), fetchStats(forceRefresh: true)]);
  }

  // =========================
  // LOAD ALL DATA
  // =========================
  Future<void> loadAllData() async {
    try {
      await Future.wait([
        _loadFeaturedCalculators(),
        _loadContinueReadingItems(),
        _loadGuidelineCategories(),
        _loadPinnedGuidelines(),
        _loadRecentlyUpdatedGuidelines(),
      ]);
    } catch (_) {
      featuredCalculators.clear();
      continueReadingItems.clear();
      guidelineCategories.clear();
      pinnedGuidelines.clear();
      recentlyUpdatedGuidelines.clear();
    }
  }

  // =====================================================
  // GUIDELINE CATEGORIES
  // =====================================================
  Future<void> _loadGuidelineCategories() async {
    try {
      isLoadingGuidelines.value = true;

      final result = await _apiService.getRecordList(
        collectionName: GuidelineCategory.collection,
        perPage: 30,
        filter: 'status="active" && parent_category=""',
        sort: 'sort_order,name',
      );

      guidelineCategories.assignAll(
        result.items.map((e) => GuidelineCategory.fromRecord(e)).toList(),
      );
    } catch (_) {
      guidelineCategories.clear();
    } finally {
      isLoadingGuidelines.value = false;
    }
  }

  // =====================================================
  // PINNED GUIDELINES
  // =====================================================
  Future<void> _loadPinnedGuidelines() async {
    try {
      final result = await _apiService.getRecordList(
        collectionName: Guideline.collection,
        perPage: 5,
        filter: 'is_published=true && status="published" && pinned=true',
        sort: '-updated',
        expand: 'categories,tags,index_item',
      );

      pinnedGuidelines.assignAll(
        result.items.map((e) => Guideline.fromRecord(e)).toList(),
      );
    } catch (_) {
      pinnedGuidelines.clear();
    }
  }

  // =====================================================
  // RECENTLY UPDATED GUIDELINES
  // =====================================================
  Future<void> _loadRecentlyUpdatedGuidelines() async {
    try {
      final result = await _apiService.getRecordList(
        collectionName: Guideline.collection,
        perPage: 5,
        filter: 'is_published=true && status="published"',
        sort: '-updated',
        expand: 'categories,tags,index_item',
      );

      recentlyUpdatedGuidelines.assignAll(
        result.items.map((e) => Guideline.fromRecord(e)).toList(),
      );
    } catch (_) {
      recentlyUpdatedGuidelines.clear();
    }
  }

  // =========================
  // CONTINUE READING
  // =========================
  Future<void> _loadContinueReadingItems() async {
    try {
      final user = _authService.currentUser.value;

      if (user == null) return;

      final records = await _apiService.getRecordList(
        collectionName: 'reading_progress',
        perPage: 6,
        filter:
            'user_id="${user.id}" && progress_percentage>0 && progress_percentage<1',
        sort: '-last_read_at',
      );

      continueReadingItems.assignAll(
        records.items.map((e) => ReadingProgress.fromRecord(e)).toList(),
      );
    } catch (_) {
      continueReadingItems.clear();
    }
  }

  // =========================
  // FEATURED CALCULATORS
  // =========================
  Future<void> _loadFeaturedCalculators() async {
    try {
      final featured = await getCalculators(
        perPage: 6,
        filter: 'featured=true && status="active"',
        sort: '-usageCount,-created',
      );

      final calculators = List<Calculator>.from(featured);

      if (calculators.length < 6) {
        final fallback = await getCalculators(
          perPage: 6 - calculators.length,
          filter: 'featured!=true && status="active"',
          sort: '-usageCount,-created',
        );

        calculators.addAll(fallback);
      }

      featuredCalculators.assignAll(calculators.take(6).toList());
    } catch (_) {
      featuredCalculators.clear();
    }
  }

  // =========================
  // CATEGORY HELPERS
  // =========================
  Color getCategoryColor(GuidelineCategory category) {
    final fromRecordColor = _tryParseColor(category.color);

    if (fromRecordColor != null) {
      return fromRecordColor;
    }

    final slug = category.slug.toLowerCase();
    final name = category.name.toLowerCase();
    final value = '$slug $name';

    if (value.contains('emergenc') || value.contains('trauma')) {
      return const Color(0xFFDC2626);
    }

    if (value.contains('infectious') ||
        value.contains('hiv') ||
        value.contains('tb')) {
      return const Color(0xFFEF4444);
    }

    if (value.contains('maternal') || value.contains('child')) {
      return const Color(0xFF8B5CF6);
    }

    if (value.contains('non-communicable') ||
        value.contains('diabetes') ||
        value.contains('ncd')) {
      return const Color(0xFFF59E0B);
    }

    if (value.contains('cardio') || value.contains('heart')) {
      return const Color(0xFFE11D48);
    }

    if (value.contains('respiratory') || value.contains('lung')) {
      return const Color(0xFF0EA5E9);
    }

    return const Color(0xFF455A64);
  }

  Color? _tryParseColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return null;

    final cleaned = hex.replaceAll('#', '').trim();

    if (cleaned.length != 6) return null;

    final value = int.tryParse('FF$cleaned', radix: 16);

    if (value == null) return null;

    return Color(value);
  }

  IconData getCategoryIcon(GuidelineCategory category) {
    final iconName = category.icon.trim().toLowerCase();

    switch (iconName) {
      case 'zap':
        return LucideIcons.zap;
      case 'bug':
        return LucideIcons.bug;
      case 'users':
        return LucideIcons.users;
      case 'heart':
        return LucideIcons.heart;
      case 'heartpulse':
      case 'heart-pulse':
        return LucideIcons.heartPulse;
      case 'wind':
        return LucideIcons.wind;
      case 'shield':
        return LucideIcons.shield;
      case 'activity':
        return LucideIcons.activity;
      case 'droplet':
        return LucideIcons.droplet;
      case 'thermometer':
        return LucideIcons.thermometer;
      case 'waves':
        return LucideIcons.waves;
      case 'alerttriangle':
      case 'alert-triangle':
        return LucideIcons.triangleAlert;
      case 'bandage':
        return LucideIcons.bandage;
      case 'skull':
        return LucideIcons.skull;
      case 'microscope':
        return LucideIcons.microscope;
      case 'flower2':
      case 'flower-2':
        return LucideIcons.flower2;
      case 'userx':
      case 'user-x':
        return LucideIcons.userX;
    }

    final slug = category.slug.toLowerCase();
    final name = category.name.toLowerCase();
    final value = '$slug $name';

    if (value.contains('emergenc') || value.contains('trauma')) {
      return LucideIcons.siren;
    }

    if (value.contains('infectious')) {
      return LucideIcons.bug;
    }

    if (value.contains('maternal') || value.contains('child')) {
      return LucideIcons.users;
    }

    if (value.contains('ncd') || value.contains('diabetes')) {
      return LucideIcons.heartPulse;
    }

    if (value.contains('cardio')) {
      return LucideIcons.heartPulse;
    }

    if (value.contains('respiratory')) {
      return LucideIcons.wind;
    }

    return LucideIcons.bookOpen;
  }

  String getCategoryDescription(GuidelineCategory category) {
    final description = category.description.trim();

    if (description.isNotEmpty) {
      return description;
    }

    final slug = category.slug.toLowerCase();
    final name = category.name.toLowerCase();
    final value = '$slug $name';

    if (value.contains('emergenc') || value.contains('trauma')) {
      return 'Emergency medicine, trauma care, poisoning and urgent response protocols';
    }

    if (value.contains('infectious')) {
      return 'Guidelines for HIV, TB, malaria, bacterial, viral and fungal infections';
    }

    if (value.contains('maternal') || value.contains('child')) {
      return 'Maternal, newborn, child health, nutrition and family planning guidance';
    }

    if (value.contains('ncd') || value.contains('non-communicable')) {
      return 'Diabetes, hypertension, cancer and chronic disease management';
    }

    if (value.contains('cardio')) {
      return 'Heart and blood vessel disease management guidance';
    }

    if (value.contains('respiratory')) {
      return 'Lung, breathing and respiratory infection management guidance';
    }

    return 'Medical protocols and treatment guidelines';
  }

  // =========================
  // NAVIGATION HELPERS
  // =========================

  /// Main user-friendly route:
  /// Home -> GuidelinesPage
  void openAllGuidelines() {
    Get.toNamed(
      AppRoutes.guidelines,
      arguments: {'filterType': 'all', 'title': 'All Guidelines'},
    );
  }

  /// Main user-friendly route:
  /// Home -> GuidelinesPage filtered by Emergency category tree
  void openEmergencyGuidelines() {
    Get.toNamed(
      AppRoutes.guidelines,
      arguments: {
        'filterType': 'categoryTree',
        'categoryId': emergencyCategoryId,
        'title': 'Emergency Guidelines',
      },
    );
  }

  /// Main user-friendly route:
  /// Home -> GuidelinesPage filtered by selected category tree
  void openGuidelineCategory(GuidelineCategory category) {
    Get.toNamed(
      AppRoutes.guidelines,
      arguments: {
        'filterType': 'categoryTree',
        'categoryId': category.id,
        'title': category.displayName,
      },
    );
  }

  /// Optional advanced route:
  /// Home -> GuidelinesIndexerPage
  void openAdvancedGuidelineBrowse() {
    Get.toNamed(
      AppRoutes.guidelinesIndexer,
      arguments: {'title': 'Advanced Browse'},
    );
  }

  void openGuideline(Guideline guideline) {
    Get.toNamed(AppRoutes.readGuideline, arguments: guideline);
  }

  Future<void> navigateToContinueReading(ReadingProgress progress) async {
    try {
      final record = await _apiService.getRecord(
        collectionName: Guideline.collection,
        recordId: progress.guidelineId,
        expand: 'categories,tags,index_item',
      );

      if (record == null) return;

      final guideline = Guideline.fromRecord(record);

      openGuideline(guideline);
    } catch (e) {
      debugPrint('Error loading guideline: $e');
    }
  }

  // =========================
  // CALCULATORS
  // =========================
  Future<List<Calculator>> getCalculators({
    int page = 1,
    int perPage = 30,
    String? filter,
    String? sort,
    String? expand,
  }) async {
    final result = await _apiService.getRecordList(
      collectionName: Calculator.collection,
      page: page,
      perPage: perPage,
      filter: filter,
      sort: sort,
      expand: expand,
    );

    return result.items.map((record) => Calculator.fromRecord(record)).toList();
  }

  Future<Calculator> createCalculator(Map<String, dynamic> data) async {
    final record = await _apiService.createRecord(
      collectionName: Calculator.collection,
      data: data,
    );

    return Calculator.fromRecord(record);
  }

  Future<Calculator> updateCalculator(
    String id,
    Map<String, dynamic> data,
  ) async {
    final record = await _apiService.updateRecord(
      collectionName: Calculator.collection,
      recordId: id,
      data: data,
    );

    return Calculator.fromRecord(record);
  }

  // =========================
  // STATS
  // =========================
  Future<void> fetchStats({bool forceRefresh = false}) async {
    if (!forceRefresh && _shouldUseStatsCache()) {
      return;
    }

    try {
      isLoadingStats.value = true;

      final response = await _apiService.getCustomEndpoint(
        path: '/api/stats',
        forceRefresh: forceRefresh,
      );

      if (response['success'] != true) {
        return;
      }

      stats.assignAll({
        'drugs': response['drugs'] ?? 0,
        'medical_guidelines': response['medical_guidelines'] ?? 0,
        'calculators': response['calculators'] ?? 0,
        'abbreviations': response['abbreviations'] ?? 0,
        'health_facilities': response['health_facilities'] ?? 0,
        'consultants': response['consultants'] ?? 0,
        'ministry_directory': response['ministry_directory'] ?? 0,
        'faqs': response['faqs'] ?? 0,
        'user_conversations_count': response['user_conversations_count'] ?? 0,
      });

      unreadMessagesCount.value = response['unread_messages_count'] ?? 0;

      _lastStatsFetch = DateTime.now();
    } catch (_) {
      stats.clear();
      unreadMessagesCount.value = 0;
    } finally {
      isLoadingStats.value = false;
    }
  }

  bool _shouldUseStatsCache() {
    if (_lastStatsFetch == null) {
      return false;
    }

    return DateTime.now().difference(_lastStatsFetch!).inMinutes < 5;
  }

  // =========================
  // STATS MODEL
  // =========================
  StatsModel get statsModel {
    return StatsModel(
      drugsCount: stats['drugs'] ?? 0,
      guidelinesCount: stats['medical_guidelines'] ?? 0,
      healthcareFacilitiesCount: stats['health_facilities'] ?? 0,
      consultantsCount: stats['consultants'] ?? 0,
      patientsServedCount: stats['calculators'] ?? 0,
      emergencyContactsCount: stats['ministry_directory'] ?? 0,
      faqsCount: stats['faqs'] ?? 0,
      unreadMessagesCount: unreadMessagesCount.value,
      userConversationsCount: stats['user_conversations_count'] ?? 0,
      lastUpdated: _lastStatsFetch ?? DateTime.now(),
    );
  }
}
