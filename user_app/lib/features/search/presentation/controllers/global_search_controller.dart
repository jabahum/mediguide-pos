import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:user_app/features/abbreviations/data/models/abbreviation.dart';
import 'package:user_app/features/calculators/data/models/calculator.dart';
import 'package:user_app/features/consultants/data/models/consultant.dart';
import 'package:user_app/features/drugs/data/models/drug.dart';
import 'package:user_app/features/guidelines/data/models/guideline.dart';
import 'package:user_app/features/facilities/data/models/health_facility.dart';
import 'package:user_app/shared/models/search_models.dart';
import 'package:user_app/features/calculators/data/repositories/calculator_repository.dart';
import 'package:user_app/features/consultants/data/repositories/consultant_repository.dart';
import 'package:user_app/features/facilities/data/repositories/facility_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/guideline_content_repository.dart';
import 'package:user_app/features/support/data/repositories/help_content_repository.dart';
import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';

final class GlobalSearchState {
  const GlobalSearchState({
    this.query = '',
    this.results = const [],
    this.validationMessage = '',
    this.isLoading = false,
    this.error,
  });

  final String query;
  final List<SearchResult> results;
  final String validationMessage;
  final bool isLoading;
  final Object? error;

  String get resultCountText {
    if (results.isEmpty) return 'No results found';
    if (results.length == 1) return '1 result';
    return '${results.length} results';
  }
}

abstract interface class GlobalSearchDataSource {
  Future<List<SearchResult>> search(String query);
}

final globalSearchDataSourceProvider = Provider<GlobalSearchDataSource>((ref) {
  return RepositoryGlobalSearchDataSource(
    drugs: ref.watch(drugRepositoryProvider),
    guidelines: ref.watch(guidelineContentRepositoryProvider),
    consultants: ref.watch(consultantRepositoryProvider),
    facilities: ref.watch(facilityRepositoryProvider),
    helpContent: ref.watch(helpContentRepositoryProvider),
    calculators: ref.watch(calculatorRepositoryProvider),
  );
});

final globalSearchControllerProvider =
    AutoDisposeNotifierProvider<GlobalSearchController, GlobalSearchState>(
      GlobalSearchController.new,
    );

class GlobalSearchController extends AutoDisposeNotifier<GlobalSearchState> {
  static const minSearchLength = 2;
  int _searchGeneration = 0;

  @override
  GlobalSearchState build() => const GlobalSearchState();

  Future<void> search(String query) async {
    final trimmed = query.trim();
    final generation = ++_searchGeneration;

    if (trimmed.isEmpty) {
      state = const GlobalSearchState();
      return;
    }
    if (trimmed.length < minSearchLength) {
      state = GlobalSearchState(
        query: trimmed,
        validationMessage: 'Enter at least $minSearchLength characters',
      );
      return;
    }

    state = GlobalSearchState(query: trimmed, isLoading: true);
    try {
      final results = await ref
          .read(globalSearchDataSourceProvider)
          .search(trimmed);
      if (generation != _searchGeneration) return;
      state = GlobalSearchState(query: trimmed, results: results);
    } catch (error) {
      if (generation != _searchGeneration) return;
      state = GlobalSearchState(query: trimmed, error: error);
    }
  }

  void clear() {
    _searchGeneration++;
    state = const GlobalSearchState();
  }

  Future<void> recordDrugUsage(String drugId) async {
    if (ref.read(authControllerProvider).valueOrNull?.user == null) return;
    try {
      await ref.read(drugRepositoryProvider).recordUsage(drugId);
    } catch (_) {
      // Usage telemetry must never prevent the user from opening a result.
    }
  }
}

final class RepositoryGlobalSearchDataSource implements GlobalSearchDataSource {
  RepositoryGlobalSearchDataSource({
    required DrugRepository drugs,
    required GuidelineContentRepository guidelines,
    required ConsultantRepository consultants,
    required FacilityRepository facilities,
    required HelpContentRepository helpContent,
    required CalculatorRepository calculators,
  }) : _drugs = drugs,
       _guidelines = guidelines,
       _consultants = consultants,
       _facilities = facilities,
       _helpContent = helpContent,
       _calculators = calculators;

  final DrugRepository _drugs;
  final GuidelineContentRepository _guidelines;
  final ConsultantRepository _consultants;
  final FacilityRepository _facilities;
  final HelpContentRepository _helpContent;
  final CalculatorRepository _calculators;

  @override
  Future<List<SearchResult>> search(String query) async {
    final batches = await Future.wait(
      SearchCategory.values
          .where((category) => category != SearchCategory.all)
          .map((category) => _searchSafely(category, query)),
    );
    final results = batches.expand((items) => items).toList()
      ..sort((a, b) {
        final relevance = b.relevanceScore.compareTo(a.relevanceScore);
        return relevance != 0
            ? relevance
            : a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    return results.take(20).toList(growable: false);
  }

  Future<List<SearchResult>> _searchSafely(
    SearchCategory category,
    String query,
  ) async {
    try {
      return await _searchCategory(category, query);
    } catch (_) {
      return const [];
    }
  }

  Future<List<SearchResult>> _searchCategory(
    SearchCategory category,
    String query,
  ) async {
    switch (category) {
      case SearchCategory.drugs:
        final response = await _drugs.list(
          page: 1,
          perPage: 10,
          search: query,
          status: 'active',
        );
        return response.items
            .map((item) => _fromRecord(item, category, query))
            .toList();
      case SearchCategory.guidelines:
        final response = await _guidelines.guidelines(
          page: 1,
          perPage: 10,
          search: query,
          published: true,
          status: 'published',
        );
        return response.items
            .map((item) => _fromRecord(item, category, query))
            .toList();
      case SearchCategory.abbreviations:
        final response = await _guidelines.abbreviations(
          page: 1,
          perPage: 10,
          search: query,
        );
        return response.items
            .map((item) => _fromRecord(item, category, query))
            .toList();
      case SearchCategory.consultants:
        final response = await _consultants.list(
          page: 1,
          perPage: 10,
          search: query,
        );
        return response.items
            .map((item) => _fromRecord(item, category, query))
            .toList();
      case SearchCategory.healthFacilities:
        final response = await _facilities.listFacilities(
          page: 1,
          perPage: 10,
          search: query,
        );
        return response.items
            .map((item) => _fromRecord(item, category, query))
            .toList();
      case SearchCategory.tools:
        final response = await _calculators.list(
          page: 1,
          perPage: 10,
          search: query,
          statuses: const ['active'],
        );
        return response.items
            .map((item) => _fromRecord(item, category, query))
            .toList();
      case SearchCategory.faq:
        final response = await _helpContent.listFAQs(
          page: 1,
          perPage: 10,
          search: query,
        );
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
              item: faq,
            ),
            query,
          );
        }).toList();
      case SearchCategory.all:
        return const [];
    }
  }

  SearchResult _fromRecord(
    dynamic record,
    SearchCategory category,
    String query,
  ) {
    switch (category) {
      case SearchCategory.drugs:
        final drug = Drug.fromRecord(record);
        return _withRelevance(
          SearchResult(
            id: drug.id,
            title: drug.name,
            subtitle: drug.brandNames.isEmpty
                ? null
                : _stripHtml(drug.brandNames),
            description: _nullableHtml(drug.description),
            category: category,
            item: drug,
          ),
          query,
        );
      case SearchCategory.guidelines:
        final guideline = Guideline.fromRecord(record);
        return _withRelevance(
          SearchResult(
            id: guideline.id,
            title: guideline.conditionName,
            subtitle: guideline.icd10Code.isEmpty ? null : guideline.icd10Code,
            description: _nullableHtml(guideline.definition),
            category: category,
            route: AppRoutes.readGuideline,
            routeArguments: {'guidelineId': guideline.id},
            item: guideline,
          ),
          query,
        );
      case SearchCategory.consultants:
        final consultant = Consultant.fromJson(record.data);
        return _withRelevance(
          SearchResult(
            id: consultant.id,
            title: consultant.name,
            subtitle: consultant.specialty?.name,
            description: consultant.department.isEmpty
                ? null
                : consultant.department,
            category: category,
            route: AppRoutes.consultants,
            routeArguments: {'consultantId': consultant.id},
            item: consultant,
          ),
          query,
        );
      case SearchCategory.healthFacilities:
        final facility = HealthFacility.fromJson(record.data);
        return _withRelevance(
          SearchResult(
            id: facility.id,
            title: facility.name,
            subtitle: facility.facilityLevelName.isEmpty
                ? null
                : facility.facilityLevelName,
            description: facility.parishName.isEmpty
                ? null
                : facility.parishName,
            category: category,
            route: AppRoutes.healthInfrastructure,
            routeArguments: {'facilityId': facility.id},
            item: facility,
          ),
          query,
        );
      case SearchCategory.abbreviations:
        final abbreviation = Abbreviation.fromRecord(record);
        return _withRelevance(
          SearchResult(
            id: abbreviation.id,
            title: abbreviation.displayAbbreviation,
            subtitle: abbreviation.meaning,
            description: _nullableHtml(abbreviation.description),
            category: category,
            route: AppRoutes.abbreviations,
            routeArguments: {'abbreviationId': abbreviation.id},
            item: abbreviation,
          ),
          query,
        );
      case SearchCategory.tools:
        final calculator = Calculator.fromJson(record.data);
        return _withRelevance(
          SearchResult(
            id: calculator.id,
            title: calculator.name,
            subtitle: calculator.type.name,
            description: _nullableHtml(calculator.description),
            category: category,
            route: AppRoutes.useCalculator,
            routeArguments: {'calculatorId': calculator.id},
            item: calculator,
          ),
          query,
        );
      case SearchCategory.all:
      case SearchCategory.faq:
        throw UnsupportedError('Unsupported search category: $category');
    }
  }

  String _stripHtml(String value) =>
      value.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  String? _nullableHtml(String value) {
    final plainText = _stripHtml(value);
    return plainText.isEmpty ? null : plainText;
  }

  SearchResult _withRelevance(SearchResult result, String query) {
    final normalizedQuery = query.toLowerCase();
    final title = result.title.toLowerCase();
    final subtitle = result.subtitle?.toLowerCase() ?? '';
    final description = result.description?.toLowerCase() ?? '';
    var score = 0.0;
    if (title == normalizedQuery) score += 100;
    if (title.startsWith(normalizedQuery)) score += 50;
    if (title.contains(normalizedQuery)) score += 25;
    if (subtitle.contains(normalizedQuery)) score += 10;
    if (description.contains(normalizedQuery)) score += 5;
    return result.copyWith(relevanceScore: score);
  }
}
