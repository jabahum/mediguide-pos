import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/search_models.dart';
import '../data/models/drug.dart';
import '../data/models/guideline.dart';
import '../data/models/consultant.dart';
import '../data/models/health_facility.dart';
import '../data/models/abbreviation.dart';
import '../data/models/calculator.dart';
import '../data/services/backend_api_service.dart';
import '../data/services/auth_service.dart';
import '../data/repositories/guideline_content_repository.dart';
import '../data/repositories/consultant_repository.dart';
import '../data/repositories/facility_repository.dart';
import '../data/repositories/help_content_repository.dart';
import '../data/repositories/calculator_repository.dart';
import '../modules/drug_index_module/widgets/drug_details_bottom_sheet.dart';
import '../routes/app_pages.dart';
import '../utils/common.dart';

/// Controller for managing global search state and logic
class GlobalSearchController extends GetxController {
  static GlobalSearchController get to => Get.find();

  // Search text controller
  final TextEditingController searchController = TextEditingController();

  // Observable state (simplified)
  final RxList<SearchResult> searchResults = <SearchResult>[].obs;
  final RxBool isLoading = false.obs;
  final RxString currentQuery = ''.obs;
  final RxString validationMessage = ''.obs;

  // Pagination
  static const int pageSize = 10;
  static const int minSearchLength = 2;
  int _searchGeneration = 0;

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Handle search submission (Enter key or manual trigger)
  void onSearchSubmitted() {
    final query = searchController.text.trim();
    currentQuery.value = query;

    if (query.isEmpty) {
      searchResults.clear();
      validationMessage.value = '';
      return;
    }

    if (query.length < minSearchLength) {
      searchResults.clear();
      validationMessage.value = 'Enter at least $minSearchLength characters';
      return;
    }

    // Start search on submit/enter
    performSearch(query);
  }

  /// Perform search with the given query
  Future<void> performSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;
    if (trimmedQuery.length < minSearchLength) {
      searchResults.clear();
      validationMessage.value = 'Enter at least $minSearchLength characters';
      return;
    }

    final generation = ++_searchGeneration;

    try {
      validationMessage.value = '';
      isLoading.value = true;
      searchResults.clear();

      final results = await _searchAllCollections(trimmedQuery);

      if (generation != _searchGeneration) return;
      searchResults.assignAll(results);
      currentQuery.value = trimmedQuery;
    } catch (e) {
      if (generation != _searchGeneration) return;
      Common.quickToast(title: 'Search failed. Please try again.');
    } finally {
      if (generation == _searchGeneration) {
        isLoading.value = false;
      }
    }
  }

  /// Clear search and reset state
  void clearSearch() {
    _searchGeneration++;
    searchController.clear();
    currentQuery.value = '';
    validationMessage.value = '';
    searchResults.clear();
  }

  /// Handle search result selection using stored objects
  Future<void> selectSearchResult(SearchResult result) async {
    switch (result.category) {
      case SearchCategory.drugs:
        final drug = result.getItem<Drug>();
        if (drug != null) {
          await _showDrugDetails(drug);
        } else {
          Common.quickToast(title: 'drugNotFound'.tr);
        }
        break;

      case SearchCategory.guidelines:
        final guideline = result.getItem<Guideline>();
        if (guideline != null) {
          Get.toNamed(AppRoutes.readGuideline, arguments: guideline);
        }
        break;

      case SearchCategory.consultants:
        final consultant = result.getItem<Consultant>();
        if (consultant != null) {
          Get.toNamed(AppRoutes.consultants, arguments: consultant);
        }
        break;

      case SearchCategory.healthFacilities:
        final facility = result.getItem<HealthFacility>();
        if (facility != null) {
          Get.toNamed(AppRoutes.healthInfrastructure, arguments: facility);
        }
        break;

      case SearchCategory.abbreviations:
        final abbreviation = result.getItem<Abbreviation>();
        if (abbreviation != null) {
          Get.toNamed(AppRoutes.abbreviations, arguments: abbreviation);
        }
        break;

      case SearchCategory.tools:
        final calculator = result.getItem<Calculator>();
        if (calculator != null) {
          Get.toNamed(AppRoutes.useCalculator, arguments: calculator);
        } else {
          Get.toNamed(
            AppRoutes.useCalculator,
            arguments: {'calculatorId': result.id},
          );
        }
        break;

      case SearchCategory.faq:
        // FAQ items store raw record data
        final faqRecord = result.item;
        if (faqRecord != null) {
          Get.toNamed(AppRoutes.faq, arguments: faqRecord);
        }
        break;

      case SearchCategory.all:
        // Should not happen, but fallback to route navigation
        if (result.route != null) {
          if (result.routeArguments != null) {
            Get.toNamed(result.route!, arguments: result.routeArguments);
          } else {
            Get.toNamed(result.route!);
          }
        }
        break;
    }
  }

  /// Show drug details bottom sheet
  Future<void> _showDrugDetails(Drug drug) async {
    try {
      // Track drug usage
      await _trackDrugUsage(drug.id);

      // Get context after async operations
      final context = Get.context;
      if (context == null || !context.mounted) return;

      // Show drug details bottom sheet
      await DrugDetailsBottomSheet.show(context: context, drug: drug);
    } catch (e) {
      Common.quickToast(title: 'errorLoadingDrugDetails'.tr);
    }
  }

  /// Track drug usage
  Future<void> _trackDrugUsage(String drugId) async {
    try {
      if (AuthService.to.currentUser.value == null) return;

      await DrugRepository(BackendApiService.to).recordUsage(drugId);
    } catch (e) {
      // Handle error silently to not disrupt user experience
    }
  }

  /// Get search result count text
  String get resultCountText {
    final count = searchResults.length;
    if (count == 0) return 'No results found';
    if (count == 1) return '1 result';
    return '$count results';
  }

  /// Search all collections in parallel with error handling
  Future<List<SearchResult>> _searchAllCollections(String query) async {
    // Launch all searches in parallel with individual error handling
    final searchFutures =
        [
          SearchCategory.drugs,
          SearchCategory.guidelines,
          SearchCategory.consultants,
          SearchCategory.healthFacilities,
          SearchCategory.abbreviations,
          SearchCategory.faq,
          SearchCategory.tools,
        ].map((category) async {
          try {
            return await _searchCollection(category, query);
          } catch (e) {
            // Return empty list if individual search fails
            return <SearchResult>[];
          }
        });

    // Wait for all searches to complete (no individual failures will break this)
    final results = await Future.wait(searchFutures);

    // Combine all successful results
    final allResults = <SearchResult>[];
    for (final categoryResults in results) {
      allResults.addAll(categoryResults);
    }

    allResults.sort((a, b) {
      final scoreComparison = b.relevanceScore.compareTo(a.relevanceScore);
      if (scoreComparison != 0) return scoreComparison;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    // Return top results (limited to 20)
    return allResults.take(20).toList();
  }

  /// Search one typed domain.
  Future<List<SearchResult>> _searchCollection(
    SearchCategory category,
    String query,
  ) async {
    try {
      if (category == SearchCategory.drugs) {
        final response = await DrugRepository(
          BackendApiService.to,
        ).list(page: 1, perPage: 10, search: query, status: 'active');
        return response.items
            .map((record) => _createSearchResult(record, category, query))
            .toList();
      }

      if (category == SearchCategory.guidelines ||
          category == SearchCategory.abbreviations) {
        final repository = GuidelineContentRepository(BackendApiService.to);
        final response = category == SearchCategory.guidelines
            ? await repository.guidelines(
                page: 1,
                perPage: 10,
                search: query,
                published: true,
                status: 'published',
              )
            : await repository.abbreviations(
                page: 1,
                perPage: 10,
                search: query,
              );
        return response.items
            .map((record) => _createSearchResult(record, category, query))
            .toList();
      }

      if (category == SearchCategory.consultants) {
        final response = await ConsultantRepository(
          BackendApiService.to,
        ).list(page: 1, perPage: 10, search: query);
        return response.items
            .map((record) => _createSearchResult(record, category, query))
            .toList();
      }

      if (category == SearchCategory.healthFacilities) {
        final response = await FacilityRepository(
          BackendApiService.to,
        ).listFacilities(page: 1, perPage: 10, search: query);
        return response.items
            .map((record) => _createSearchResult(record, category, query))
            .toList();
      }

      if (category == SearchCategory.tools) {
        final response = await CalculatorRepository(
          BackendApiService.to,
        ).list(page: 1, perPage: 10, search: query, statuses: const ['active']);
        return response.items
            .map((record) => _createSearchResult(record, category, query))
            .toList();
      }

      if (category == SearchCategory.faq) {
        final response = await HelpContentRepository(
          BackendApiService.to,
        ).listFAQs(page: 1, perPage: 10, search: query);
        return response.items.map((faq) {
          final answer = _stripHtml(faq.answer);
          return _withRelevance(
            SearchResult(
              id: faq.id,
              title: _stripHtml(faq.question),
              description: answer.length > 100
                  ? '${answer.substring(0, 100)}...'
                  : answer,
              category: category,
              route: AppRoutes.faq,
              routeArguments: {'faqId': faq.id},
              relevanceScore: 0,
              item: faq,
            ),
            query,
          );
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Strip HTML tags from rich text fields
  String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  double _calculateRelevance({
    required String query,
    required String title,
    String? subtitle,
    String? description,
  }) {
    final normalizedQuery = query.toLowerCase();
    final normalizedTitle = title.toLowerCase();
    final normalizedSubtitle = subtitle?.toLowerCase() ?? '';
    final normalizedDescription = description?.toLowerCase() ?? '';

    var score = 0.0;
    if (normalizedTitle == normalizedQuery) score += 100;
    if (normalizedTitle.startsWith(normalizedQuery)) score += 50;
    if (normalizedTitle.contains(normalizedQuery)) score += 25;
    if (normalizedSubtitle.contains(normalizedQuery)) score += 10;
    if (normalizedDescription.contains(normalizedQuery)) score += 5;
    return score;
  }

  SearchResult _withRelevance(SearchResult result, String query) {
    return result.copyWith(
      relevanceScore: _calculateRelevance(
        query: query,
        title: result.title,
        subtitle: result.subtitle,
        description: result.description,
      ),
    );
  }

  /// Create SearchResult from backend resource API record
  SearchResult _createSearchResult(
    dynamic record,
    SearchCategory category,
    String query,
  ) {
    switch (category) {
      case SearchCategory.drugs:
        final drug = Drug.fromRecord(record);
        final drugDesc = _stripHtml(drug.description);
        return _withRelevance(
          SearchResult(
            id: drug.id,
            title: drug.name,
            subtitle: drug.brandNames.isNotEmpty
                ? _stripHtml(drug.brandNames)
                : null,
            description: drugDesc.isNotEmpty ? drugDesc : null,
            category: category,
            route: null,
            routeArguments: null,
            relevanceScore: 0.0,
            item: drug,
          ),
          query,
        );

      case SearchCategory.guidelines:
        final guideline = Guideline.fromRecord(record);
        final guidelineDesc = _stripHtml(guideline.definition);
        return _withRelevance(
          SearchResult(
            id: guideline.id,
            title: guideline.conditionName,
            subtitle: guideline.icd10Code.isNotEmpty
                ? guideline.icd10Code
                : null,
            description: guidelineDesc.isNotEmpty ? guidelineDesc : null,
            category: category,
            route: AppRoutes.readGuideline,
            routeArguments: {'guidelineId': guideline.id},
            relevanceScore: 0.0,
            item: guideline,
          ),
          query,
        );

      case SearchCategory.consultants:
        final consultant = Consultant.fromRecord(record);
        return _withRelevance(
          SearchResult(
            id: consultant.id,
            title: consultant.name,
            subtitle: consultant.specialty?.name,
            description: consultant.department.isNotEmpty
                ? consultant.department
                : null,
            category: category,
            route: AppRoutes.consultants,
            routeArguments: {'consultantId': consultant.id},
            relevanceScore: 0.0,
            item: consultant,
          ),
          query,
        );

      case SearchCategory.healthFacilities:
        final facility = HealthFacility.fromRecord(record);
        return _withRelevance(
          SearchResult(
            id: facility.id,
            title: facility.name,
            subtitle: facility.facilityLevelName.isNotEmpty
                ? facility.facilityLevelName
                : null,
            description: facility.parishName.isNotEmpty
                ? facility.parishName
                : null,
            category: category,
            route: AppRoutes.healthInfrastructure,
            routeArguments: {'facilityId': facility.id},
            relevanceScore: 0.0,
            item: facility,
          ),
          query,
        );

      case SearchCategory.abbreviations:
        final abbreviation = Abbreviation.fromRecord(record);
        final abbrDesc = _stripHtml(abbreviation.description);
        return _withRelevance(
          SearchResult(
            id: abbreviation.id,
            title: abbreviation.displayAbbreviation,
            subtitle: abbreviation.meaning,
            description: abbrDesc.isNotEmpty ? abbrDesc : null,
            category: category,
            route: AppRoutes.abbreviations,
            routeArguments: {'abbreviationId': abbreviation.id},
            relevanceScore: 0.0,
            item: abbreviation,
          ),
          query,
        );

      case SearchCategory.tools:
        final calculator = Calculator.fromRecord(record);
        final calcDesc = _stripHtml(calculator.description);
        return _withRelevance(
          SearchResult(
            id: calculator.id,
            title: calculator.name,
            subtitle: calculator.type.name,
            description: calcDesc.isNotEmpty ? calcDesc : null,
            category: category,
            route: AppRoutes.useCalculator,
            routeArguments: {'calculatorId': calculator.id},
            relevanceScore: 0.0,
            item: calculator,
          ),
          query,
        );

      case SearchCategory.faq:
        final data = record.data;
        final faqAnswer = _stripHtml(data['answer'] ?? '');
        return _withRelevance(
          SearchResult(
            id: record.id,
            title: _stripHtml(data['question'] ?? 'FAQ'),
            subtitle: null,
            description: faqAnswer.length > 100
                ? '${faqAnswer.substring(0, 100)}...'
                : faqAnswer,
            category: category,
            route: AppRoutes.faq,
            routeArguments: {'faqId': record.id},
            relevanceScore: 0.0,
            item: record,
          ),
          query,
        );

      default:
        throw UnsupportedError('Unsupported search category: $category');
    }
  }
}
