class FAQ {
  final String id;
  final String question;
  final String answer;
  final String status;
  final String priority;
  final int sortOrder;
  final bool isFeatured;
  final String targetAudience;
  final String keywords;
  final DateTime? publishedAt;
  final DateTime? reviewDue;
  final List<String> tags;
  final List<String> relatedFaqs;
  final String? author;
  final String? reviewer;
  final DateTime created;
  final DateTime updated;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    this.status = 'published',
    this.priority = 'normal',
    this.sortOrder = 0,
    this.isFeatured = false,
    this.targetAudience = 'all',
    this.keywords = '',
    this.publishedAt,
    this.reviewDue,
    this.tags = const [],
    this.relatedFaqs = const [],
    this.author,
    this.reviewer,
    required this.created,
    required this.updated,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      status: json['status'] ?? 'published',
      priority: json['priority'] ?? 'normal',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isFeatured: json['is_featured'] ?? false,
      targetAudience: json['target_audience'] ?? 'all',
      keywords: json['keywords'] ?? '',
      publishedAt:
          json['published_at'] != null && json['published_at'].isNotEmpty
          ? DateTime.tryParse(json['published_at'])
          : null,
      reviewDue: json['review_due'] != null && json['review_due'].isNotEmpty
          ? DateTime.tryParse(json['review_due'])
          : null,
      tags: json['tags'] is List ? List<String>.from(json['tags']) : [],
      relatedFaqs: json['related_faqs'] is List
          ? List<String>.from(json['related_faqs'])
          : [],
      author: json['author'],
      reviewer: json['reviewer'],
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'status': status,
      'priority': priority,
      'sort_order': sortOrder,
      'is_featured': isFeatured,
      'target_audience': targetAudience,
      'keywords': keywords,
      'published_at': publishedAt?.toIso8601String(),
      'review_due': reviewDue?.toIso8601String(),
      'tags': tags,
      'related_faqs': relatedFaqs,
      'author': author,
      'reviewer': reviewer,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FAQ && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'FAQ{id: $id, question: $question, isFeatured: $isFeatured}';
}

/// FAQ Priority enum with enhanced enum features
enum FaqPriority {
  low(label: 'Low', sortOrder: 1),
  normal(label: 'Normal', sortOrder: 2),
  high(label: 'High', sortOrder: 3),
  critical(label: 'Critical', sortOrder: 4);

  const FaqPriority({required this.label, required this.sortOrder});

  final String label;
  final int sortOrder;

  static FaqPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return FaqPriority.low;
      case 'high':
        return FaqPriority.high;
      case 'critical':
        return FaqPriority.critical;
      case 'normal':
      default:
        return FaqPriority.normal;
    }
  }
}

/// FAQ Status enum
enum FaqStatus {
  draft(label: 'Draft'),
  review(label: 'Review'),
  published(label: 'Published'),
  archived(label: 'Archived');

  const FaqStatus({required this.label});

  final String label;

  static FaqStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return FaqStatus.draft;
      case 'review':
        return FaqStatus.review;
      case 'archived':
        return FaqStatus.archived;
      case 'published':
      default:
        return FaqStatus.published;
    }
  }
}

/// FAQ Target Audience enum
enum FaqTargetAudience {
  all(label: 'All Users'),
  admin(label: 'Admin'),
  healthWorker(label: 'Health Worker'),
  patient(label: 'Patient');

  const FaqTargetAudience({required this.label});

  final String label;

  static FaqTargetAudience fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return FaqTargetAudience.admin;
      case 'health_worker':
        return FaqTargetAudience.healthWorker;
      case 'patient':
        return FaqTargetAudience.patient;
      case 'all':
      default:
        return FaqTargetAudience.all;
    }
  }
}
