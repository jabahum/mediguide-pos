// ignore_for_file: unused_field

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/features/drugs/data/models/drug_enums.dart';
import 'package:user_app/shared/models/base_model.dart';
import 'package:user_app/features/drugs/data/models/drug_category.dart';
import 'package:user_app/features/drugs/data/models/drug_tag.dart';
import 'package:user_app/features/drugs/data/models/drug_class.dart';
import 'package:user_app/features/drugs/data/models/therapeutic_category.dart';

/// Drug model based on backend resource API drugs collection
class Drug extends BaseModel {
  Drug(super.data);

  /// backend resource API collection name
  static const String collection = 'drugs';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => Drug(data));
    return true;
  })();

  /// Create Drug from backend resource API record
  static Drug fromRecord(ApiRecord record) => Drug(record.data);

  /// Create JSON for new drug record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    String? brandNames,
    String? description,
    String? mechanismOfAction,
    String? adultDose,
    String? pediatricDose,
    String? elderlyDose,
    String? maxDailyDose,
    List<RouteOfAdministration>? routeOfAdministration,
    String? frequency,
    String? duration,
    String? indications,
    String? contraindications,
    String? sideEffects,
    String? warnings,
    String? monitoringParameters,
    PregnancyCategory? pregnancyCategory,
    String? clinicalNotes,
    List<String>? categoryIds,
    List<String>? tagIds,
    String? drugClassId,
    String? therapeuticCategoryId,
    bool? whoEmlStatus,
    bool? antimicrobialStatus,
    ControlledSubstance? controlledSubstance,
    DrugStatus? status,
    ReviewStatus? reviewStatus,
    String? searchKeywords,
    String? references,
  }) {
    return {
      'name': name,
      'brand_names': ?brandNames,
      'description': ?description,
      'mechanism_of_action': ?mechanismOfAction,
      'adult_dose': ?adultDose,
      'pediatric_dose': ?pediatricDose,
      'elderly_dose': ?elderlyDose,
      'max_daily_dose': ?maxDailyDose,
      if (routeOfAdministration != null)
        'route_of_administration': routeOfAdministration
            .map((r) => r.name)
            .toList(),
      'frequency': ?frequency,
      'duration': ?duration,
      'indications': ?indications,
      'contraindications': ?contraindications,
      'side_effects': ?sideEffects,
      'warnings': ?warnings,
      'monitoring_parameters': ?monitoringParameters,
      if (pregnancyCategory != null)
        'pregnancy_category': pregnancyCategory.name.toUpperCase(),
      'clinical_notes': ?clinicalNotes,
      'categories': ?categoryIds,
      'tags': ?tagIds,
      'drug_class': ?drugClassId,
      'therapeutic_category': ?therapeuticCategoryId,
      'who_eml_status': ?whoEmlStatus,
      'antimicrobial_status': ?antimicrobialStatus,
      if (controlledSubstance != null)
        'controlled_substance': _controlledSubstanceToString(
          controlledSubstance,
        ),
      'status': (status ?? DrugStatus.active).name,
      'review_status': (reviewStatus ?? ReviewStatus.pending).name,
      'search_keywords': ?searchKeywords,
      'references': ?references,
    };
  }

  // Direct string properties - late final for performance
  late final String name = get<String>("name", "");
  late final String brandNames = get<String>("brand_names", "");
  late final String description = get<String>("description", "");
  late final String mechanismOfAction = get<String>("mechanism_of_action", "");
  late final String adultDose = get<String>("adult_dose", "");
  late final String pediatricDose = get<String>("pediatric_dose", "");
  late final String elderlyDose = get<String>("elderly_dose", "");
  late final String maxDailyDose = get<String>("max_daily_dose", "");
  late final String frequency = get<String>("frequency", "");
  late final String duration = get<String>("duration", "");
  late final String indications = get<String>("indications", "");
  late final String contraindications = get<String>("contraindications", "");
  late final String sideEffects = get<String>("side_effects", "");
  late final String warnings = get<String>("warnings", "");
  late final String monitoringParameters = get<String>(
    "monitoring_parameters",
    "",
  );
  late final String clinicalNotes = get<String>("clinical_notes", "");
  late final String searchKeywords = get<String>("search_keywords", "");
  late final String references = get<String>("references", "");

  // Boolean properties
  late final bool whoEmlStatus = get<bool>("who_eml_status", false);
  late final bool antimicrobialStatus = get<bool>(
    "antimicrobial_status",
    false,
  );

  // Enum properties
  late final List<RouteOfAdministration> routeOfAdministration =
      getEnumList<RouteOfAdministration>(
        "route_of_administration",
        RouteOfAdministration.values,
      );
  late final PregnancyCategory? pregnancyCategory = getEnum<PregnancyCategory>(
    "pregnancy_category",
    PregnancyCategory.values,
  );
  late final ControlledSubstance? controlledSubstance =
      _parseControlledSubstance(get<String>("controlled_substance", ""));
  late final DrugStatus status =
      getEnum<DrugStatus>("status", DrugStatus.values) ?? DrugStatus.active;
  late final ReviewStatus reviewStatus =
      getEnum<ReviewStatus>("review_status", ReviewStatus.values) ??
      ReviewStatus.pending;

  // Typed relationship projections. The API currently returns category/tag
  // display names and explicit class/category IDs instead of expansion maps.
  late final List<DrugCategory> categories = _categories();
  late final List<DrugTag> tags = _tags();
  late final DrugClass? drugClass = _drugClass();
  late final TherapeuticCategory? therapeuticCategory = _therapeuticCategory();

  List<DrugCategory> _categories() => _relationList(
    'categories',
    (json) => DrugCategory.fromJson(json),
    (name) => DrugCategory(id: '', name: name),
  );

  List<DrugTag> _tags() => _relationList(
    'tags',
    (json) => DrugTag.fromJson(json),
    (name) => DrugTag(id: '', name: name),
  );

  List<T> _relationList<T>(
    String field,
    T Function(Map<String, dynamic>) fromJson,
    T Function(String) fromName,
  ) {
    final raw = data[field];
    if (raw is! List) return const [];
    return raw
        .map<T?>((value) {
          if (value is Map) {
            return fromJson(Map<String, dynamic>.from(value));
          }
          final name = value?.toString().trim() ?? '';
          return name.isEmpty ? null : fromName(name);
        })
        .whereType<T>()
        .toList(growable: false);
  }

  DrugClass? _drugClass() {
    final id = get<String>('drug_class', '');
    final expanded = get<Map<String, dynamic>?>('expand.drug_class', null);
    if (expanded != null) return DrugClass.fromJson(expanded);
    final name = get<String>('drug_class_name', '');
    return id.isEmpty && name.isEmpty ? null : DrugClass(id: id, name: name);
  }

  TherapeuticCategory? _therapeuticCategory() {
    final id = get<String>('therapeutic_category', '');
    final expanded = get<Map<String, dynamic>?>(
      'expand.therapeutic_category',
      null,
    );
    if (expanded != null) return TherapeuticCategory.fromJson(expanded);
    final name = get<String>('therapeutic_category_name', '');
    return id.isEmpty && name.isEmpty
        ? null
        : TherapeuticCategory(id: id, name: name);
  }

  // Helper methods for controlled substance conversion
  static String _controlledSubstanceToString(ControlledSubstance substance) {
    switch (substance) {
      case ControlledSubstance.none:
        return 'None';
      case ControlledSubstance.scheduleI:
        return 'Schedule I';
      case ControlledSubstance.scheduleII:
        return 'Schedule II';
      case ControlledSubstance.scheduleIII:
        return 'Schedule III';
      case ControlledSubstance.scheduleIV:
        return 'Schedule IV';
      case ControlledSubstance.scheduleV:
        return 'Schedule V';
    }
  }

  static ControlledSubstance? _parseControlledSubstance(String value) {
    switch (value.toLowerCase()) {
      case 'none':
        return ControlledSubstance.none;
      case 'schedule i':
        return ControlledSubstance.scheduleI;
      case 'schedule ii':
        return ControlledSubstance.scheduleII;
      case 'schedule iii':
        return ControlledSubstance.scheduleIII;
      case 'schedule iv':
        return ControlledSubstance.scheduleIV;
      case 'schedule v':
        return ControlledSubstance.scheduleV;
      default:
        return null;
    }
  }
}
