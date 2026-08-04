class GenericPage {
  final String id;
  final String title;
  final String? description;
  final Map<String, dynamic>? content;
  final String key;
  final DateTime created;
  final DateTime updated;

  const GenericPage({
    required this.id,
    required this.title,
    this.description,
    this.content,
    required this.key,
    required this.created,
    required this.updated,
  });

  factory GenericPage.fromJson(Map<String, dynamic> json) {
    return GenericPage(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      content: json['content'],
      key: json['key'],
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'key': key,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  GenericPage copyWith({
    String? id,
    String? title,
    String? description,
    Map<String, dynamic>? content,
    String? key,
    DateTime? created,
    DateTime? updated,
  }) {
    return GenericPage(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      key: key ?? this.key,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  String toString() {
    return 'GenericPage(id: $id, title: $title, key: $key)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GenericPage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Content type detection and parsing methods

  /// Check if content is a simple string
  bool get isStringContent {
    if (content == null) return false;
    // If content has only one key and it's a string value, treat as string content
    if (content!.length == 1 && content!.values.first is String) return true;
    return false;
  }

  /// Check if content has key-value structure with title and content pairs
  bool get isKeyValueContent {
    if (content == null || content!.isEmpty) return false;
    if (isStringContent) return false;

    // Check if all values are maps with title/content structure
    return content!.values.every(
      (value) =>
          value is Map<String, dynamic> &&
          value.containsKey('title') &&
          value.containsKey('content'),
    );
  }

  /// Get string content for HTML display
  String get stringContent {
    if (!isStringContent) return '';
    return content!.values.first as String;
  }

  /// Get sections for key-value content
  List<GenericPageSection> get sections {
    if (!isKeyValueContent) return [];

    return content!.entries.map((entry) {
      final sectionData = entry.value as Map<String, dynamic>;
      return GenericPageSection(
        key: entry.key,
        title: sectionData['title'] as String,
        content: sectionData['content'] as String,
      );
    }).toList();
  }

  /// Check if page has any content to display
  bool get hasContent {
    return content != null && content!.isNotEmpty;
  }
}

/// Represents a section in key-value structured content
class GenericPageSection {
  final String key;
  final String title;
  final String content;

  const GenericPageSection({
    required this.key,
    required this.title,
    required this.content,
  });

  @override
  String toString() {
    return 'GenericPageSection(key: $key, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenericPageSection && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}
