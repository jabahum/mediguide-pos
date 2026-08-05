// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReadingProgress _$ReadingProgressFromJson(Map<String, dynamic> json) =>
    _ReadingProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      guidelineId: json['guideline_id'] as String? ?? '',
      currentSection: json['current_section'] as String? ?? '',
      totalSections: (json['total_sections'] as num?)?.toInt() ?? 0,
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ?? 0,
      lastReadAtValue: const NullableDateTimeConverter().fromJson(
        json['last_read_at'],
      ),
      isCompleted: json['is_completed'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      pendingSync: json['pending_sync'] as bool? ?? false,
      createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
      updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$ReadingProgressToJson(
  _ReadingProgress instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'guideline_id': instance.guidelineId,
  'current_section': instance.currentSection,
  'total_sections': instance.totalSections,
  'progress_percentage': instance.progressPercentage,
  'last_read_at': const NullableDateTimeConverter().toJson(
    instance.lastReadAtValue,
  ),
  'is_completed': instance.isCompleted,
  'is_bookmarked': instance.isBookmarked,
  'notes': instance.notes,
  'pending_sync': instance.pendingSync,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

_ReadingProgressRequest _$ReadingProgressRequestFromJson(
  Map<String, dynamic> json,
) => _ReadingProgressRequest(
  guidelineId: json['guideline_id'] as String?,
  currentSection: json['current_section'] as String?,
  totalSections: (json['total_sections'] as num?)?.toInt(),
  progressPercentage: (json['progress_percentage'] as num?)?.toDouble(),
  lastReadAt: json['last_read_at'] == null
      ? null
      : DateTime.parse(json['last_read_at'] as String),
  isCompleted: json['is_completed'] as bool?,
  isBookmarked: json['is_bookmarked'] as bool?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$ReadingProgressRequestToJson(
  _ReadingProgressRequest instance,
) => <String, dynamic>{
  if (instance.guidelineId case final value?) 'guideline_id': value,
  if (instance.currentSection case final value?) 'current_section': value,
  if (instance.totalSections case final value?) 'total_sections': value,
  if (instance.progressPercentage case final value?)
    'progress_percentage': value,
  if (instance.lastReadAt?.toIso8601String() case final value?)
    'last_read_at': value,
  if (instance.isCompleted case final value?) 'is_completed': value,
  if (instance.isBookmarked case final value?) 'is_bookmarked': value,
  if (instance.notes case final value?) 'notes': value,
};
