import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';

part 'reading_progress.freezed.dart';
part 'reading_progress.g.dart';

@freezed
abstract class ReadingProgress with _$ReadingProgress {
  const ReadingProgress._();
  const factory ReadingProgress({
    required String id,
    @JsonKey(name: 'user_id') @Default('') String userId,
    @JsonKey(name: 'guideline_id') @Default('') String guidelineId,
    @JsonKey(name: 'current_section') @Default('') String currentSection,
    @JsonKey(name: 'total_sections') @Default(0) int totalSections,
    @JsonKey(name: 'progress_percentage') @Default(0) double progressPercentage,
    @JsonKey(name: 'last_read_at')
    @NullableDateTimeConverter()
    DateTime? lastReadAtValue,
    @JsonKey(name: 'is_completed') @Default(false) bool isCompleted,
    @JsonKey(name: 'is_bookmarked') @Default(false) bool isBookmarked,
    @Default('') String notes,
    @JsonKey(name: 'pending_sync') @Default(false) bool pendingSync,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _ReadingProgress;
  factory ReadingProgress.fromJson(Map<String, dynamic> json) =>
      _$ReadingProgressFromJson(json);

  DateTime get lastReadAt => lastReadAtValue ?? DateTime.now();

  String get progressText => '${(progressPercentage * 100).toInt()}%';
  bool get isInProgress => progressPercentage > 0 && !isCompleted;
  bool get isRecentlyRead => DateTime.now().difference(lastReadAt).inDays <= 7;
  String get lastReadFormatted {
    final difference = DateTime.now().difference(lastReadAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  ReadingStatus get status => isCompleted
      ? ReadingStatus.completed
      : progressPercentage > 0
      ? ReadingStatus.inProgress
      : ReadingStatus.notStarted;
  String get sectionProgress =>
      '${_sectionNumber(currentSection)}/$totalSections';
}

int _sectionNumber(String value) {
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
  final index = sections.indexOf(value.toLowerCase());
  return index < 0 ? 1 : index + 1;
}

@freezed
abstract class ReadingProgressRequest with _$ReadingProgressRequest {
  @JsonSerializable(includeIfNull: false)
  const factory ReadingProgressRequest({
    @JsonKey(name: 'guideline_id') String? guidelineId,
    @JsonKey(name: 'current_section') String? currentSection,
    @JsonKey(name: 'total_sections') int? totalSections,
    @JsonKey(name: 'progress_percentage') double? progressPercentage,
    @JsonKey(name: 'last_read_at') DateTime? lastReadAt,
    @JsonKey(name: 'is_completed') bool? isCompleted,
    @JsonKey(name: 'is_bookmarked') bool? isBookmarked,
    String? notes,
  }) = _ReadingProgressRequest;
  factory ReadingProgressRequest.fromJson(Map<String, dynamic> json) =>
      _$ReadingProgressRequestFromJson(json);
}

enum ReadingStatus {
  notStarted(label: 'Not Started', colorKey: 'grey'),
  inProgress(label: 'In Progress', colorKey: 'blue'),
  completed(label: 'Completed', colorKey: 'green');

  const ReadingStatus({required this.label, required this.colorKey});
  final String label;
  final String colorKey;
}

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
}
