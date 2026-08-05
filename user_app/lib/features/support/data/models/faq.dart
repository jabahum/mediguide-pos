import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';

part 'faq.freezed.dart';
part 'faq.g.dart';

@freezed
abstract class FAQ with _$FAQ {
  const FAQ._();

  const factory FAQ({
    required String id,
    @Default('') String question,
    @Default('') String answer,
    @Default('published') String status,
    @Default('normal') String priority,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'is_featured') @Default(false) bool isFeatured,
    @JsonKey(name: 'target_audience') @Default('all') String targetAudience,
    @Default('') String keywords,
    @JsonKey(name: 'published_at')
    @NullableDateTimeConverter()
    DateTime? publishedAt,
    @JsonKey(name: 'review_due')
    @NullableDateTimeConverter()
    DateTime? reviewDue,
    @Default([]) List<String> tags,
    @JsonKey(name: 'related_faqs') @Default([]) List<String> relatedFaqs,
    String? author,
    String? reviewer,
    @NullableDateTimeConverter() DateTime? created,
    @NullableDateTimeConverter() DateTime? updated,
  }) = _FAQ;

  factory FAQ.fromJson(Map<String, dynamic> json) => _$FAQFromJson(json);
}

enum FaqPriority {
  low(label: 'Low', sortOrder: 1),
  normal(label: 'Normal', sortOrder: 2),
  high(label: 'High', sortOrder: 3),
  critical(label: 'Critical', sortOrder: 4);

  const FaqPriority({required this.label, required this.sortOrder});
  final String label;
  final int sortOrder;

  static FaqPriority fromString(String value) => switch (value.toLowerCase()) {
    'low' => FaqPriority.low,
    'high' => FaqPriority.high,
    'critical' => FaqPriority.critical,
    _ => FaqPriority.normal,
  };
}

enum FaqStatus {
  draft(label: 'Draft'),
  review(label: 'Review'),
  published(label: 'Published'),
  archived(label: 'Archived');

  const FaqStatus({required this.label});
  final String label;

  static FaqStatus fromString(String value) => switch (value.toLowerCase()) {
    'draft' => FaqStatus.draft,
    'review' => FaqStatus.review,
    'archived' => FaqStatus.archived,
    _ => FaqStatus.published,
  };
}

enum FaqTargetAudience {
  all(label: 'All Users'),
  admin(label: 'Admin'),
  healthWorker(label: 'Health Worker'),
  patient(label: 'Patient');

  const FaqTargetAudience({required this.label});
  final String label;

  static FaqTargetAudience fromString(String value) =>
      switch (value.toLowerCase()) {
        'admin' => FaqTargetAudience.admin,
        'health_worker' => FaqTargetAudience.healthWorker,
        'patient' => FaqTargetAudience.patient,
        _ => FaqTargetAudience.all,
      };
}
