import 'package:user_app/app/data/models/api_record.dart';
import 'base_model.dart';

/// Reading progress tracking model for user guideline reading status
class ReadingProgress extends BaseModel {
  ReadingProgress(super.data);

  /// Create ReadingProgress from backend resource API record
  static ReadingProgress fromRecord(ApiRecord record) =>
      ReadingProgress(record.data);

  /// Create JSON for new reading progress record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String userId,
    required String guidelineId,
    required String currentSection,
    required int totalSections,
    required double progressPercentage,
    DateTime? lastReadAt,
    bool? isCompleted,
    bool? isBookmarked,
    String? notes,
  }) {
    return {
      'user_id': userId,
      'guideline_id': guidelineId,
      'current_section': currentSection,
      'total_sections': totalSections,
      'progress_percentage': progressPercentage,
      'last_read_at':
          lastReadAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'is_completed': isCompleted ?? false,
      'is_bookmarked': isBookmarked ?? false,
      'notes': ?notes,
    };
  }

  // Core fields
  late final String userId = get<String>("user_id", "");
  late final String guidelineId = get<String>("guideline_id", "");
  late final String currentSection = get<String>("current_section", "");
  late final int totalSections = get<int>("total_sections", 0);
  late final double progressPercentage = get<double>(
    "progress_percentage",
    0.0,
  );
  late final DateTime lastReadAt =
      DateTime.tryParse(get<String>("last_read_at", "")) ?? DateTime.now();
  late final bool isCompleted = get<bool>("is_completed", false);
  late final bool isBookmarked = get<bool>("is_bookmarked", false);
  late final String notes = get<String>("notes", "");

  // Computed properties

  /// Get formatted progress percentage as string
  String get progressText => "${(progressPercentage * 100).toInt()}%";

  /// Check if reading was started but not completed
  bool get isInProgress => progressPercentage > 0 && !isCompleted;

  /// Check if reading was started recently (within 7 days)
  bool get isRecentlyRead {
    final now = DateTime.now();
    final difference = now.difference(lastReadAt);
    return difference.inDays <= 7;
  }

  /// Get formatted last read time
  String get lastReadFormatted {
    final now = DateTime.now();
    final difference = now.difference(lastReadAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  /// Get reading status as enum
  ReadingStatus get status {
    if (isCompleted) return ReadingStatus.completed;
    if (progressPercentage > 0) return ReadingStatus.inProgress;
    return ReadingStatus.notStarted;
  }

  /// Get section progress as "current/total"
  String get sectionProgress {
    final currentSectionNumber = _getSectionNumber(currentSection);
    return '$currentSectionNumber/$totalSections';
  }

  /// Helper to get current section number
  int _getSectionNumber(String sectionName) {
    const sections = [
      'definition',
      'causes',
      'clinical_features',
      'differential_diagnosis',
      'classification',
      'general_management',
      'medication',
      'monitoring',
      'prevention',
      'special_notes',
    ];

    final index = sections.indexOf(sectionName.toLowerCase());
    return index >= 0 ? index + 1 : 1;
  }
}

/// Reading status enumeration
enum ReadingStatus {
  notStarted(label: 'Not Started', colorKey: 'grey'),
  inProgress(label: 'In Progress', colorKey: 'blue'),
  completed(label: 'Completed', colorKey: 'green');

  const ReadingStatus({required this.label, required this.colorKey});

  final String label;
  final String colorKey;
}

/// Guideline sections for navigation and progress tracking
enum GuidelineSection {
  definition(label: 'Definition', fieldName: 'definition'),
  causes(label: 'Causes', fieldName: 'causes'),
  clinicalFeatures(label: 'Clinical Features', fieldName: 'clinical_features'),
  differentialDiagnosis(
    label: 'Differential Diagnosis',
    fieldName: 'differential_diagnosis',
  ),
  classification(label: 'Classification', fieldName: 'classification_mild'),
  generalManagement(
    label: 'General Management',
    fieldName: 'general_management',
  ),
  medication(label: 'Medication', fieldName: 'medication_primary'),
  monitoring(label: 'Monitoring', fieldName: 'monitoring_requirements'),
  prevention(label: 'Prevention', fieldName: 'prevention_measures'),
  specialNotes(label: 'Special Notes', fieldName: 'special_notes');

  const GuidelineSection({required this.label, required this.fieldName});

  final String label;
  final String fieldName;

  /// Get section from field name
  static GuidelineSection? fromFieldName(String fieldName) {
    switch (fieldName) {
      case 'definition':
        return GuidelineSection.definition;
      case 'causes':
        return GuidelineSection.causes;
      case 'clinical_features':
        return GuidelineSection.clinicalFeatures;
      case 'differential_diagnosis':
        return GuidelineSection.differentialDiagnosis;
      case 'classification_mild':
      case 'classification_moderate':
      case 'classification_severe':
      case 'classification_critical':
        return GuidelineSection.classification;
      case 'general_management':
        return GuidelineSection.generalManagement;
      case 'medication_primary':
      case 'medication_secondary':
        return GuidelineSection.medication;
      case 'monitoring_requirements':
        return GuidelineSection.monitoring;
      case 'prevention_measures':
        return GuidelineSection.prevention;
      case 'special_notes':
        return GuidelineSection.specialNotes;
      default:
        return null;
    }
  }
}
