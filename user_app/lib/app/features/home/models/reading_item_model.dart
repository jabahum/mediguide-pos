/// Model representing a reading item (guideline, article, protocol)
class ReadingItemModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final int totalPages;
  final int currentPage;
  final DateTime lastReadAt;
  final DateTime publishedAt;
  final String author;
  final List<String> tags;
  final bool isBookmarked;
  final String contentUrl;
  final ReadingItemType type;

  const ReadingItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.totalPages,
    required this.currentPage,
    required this.lastReadAt,
    required this.publishedAt,
    required this.author,
    required this.tags,
    required this.isBookmarked,
    required this.contentUrl,
    required this.type,
  });

  factory ReadingItemModel.fromJson(Map<String, dynamic> json) {
    return ReadingItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String,
      totalPages: json['totalPages'] as int,
      currentPage: json['currentPage'] as int,
      lastReadAt: DateTime.parse(json['lastReadAt'] as String),
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      author: json['author'] as String,
      tags: List<String>.from(json['tags'] as List),
      isBookmarked: json['isBookmarked'] as bool,
      contentUrl: json['contentUrl'] as String,
      type: ReadingItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReadingItemType.guideline,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'lastReadAt': lastReadAt.toIso8601String(),
      'publishedAt': publishedAt.toIso8601String(),
      'author': author,
      'tags': tags,
      'isBookmarked': isBookmarked,
      'contentUrl': contentUrl,
      'type': type.name,
    };
  }

  /// Reading progress as percentage (0.0 to 1.0)
  double get progress => currentPage / totalPages;

  /// Formatted progress percentage
  String get progressPercentage => '${(progress * 100).round()}%';

  /// Whether the item is completed
  bool get isCompleted => currentPage >= totalPages;

  /// Whether reading has started
  bool get isStarted => currentPage > 0;

  /// Reading status text
  String get statusText {
    if (isCompleted) return 'Completed';
    if (isStarted) return 'In Progress';
    return 'Not Started';
  }

  /// Formatted time since last read
  String get timeSinceLastRead {
    final now = DateTime.now();
    final difference = now.difference(lastReadAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Estimated reading time remaining in minutes
  int get estimatedTimeRemaining {
    const averagePagesPerMinute = 2;
    final pagesRemaining = totalPages - currentPage;
    return (pagesRemaining / averagePagesPerMinute).ceil();
  }

  /// Type icon based on reading item type
  String get typeIcon => type.icon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ReadingItemModel{id: $id, title: $title, progress: $progressPercentage}';
  }
}

/// Types of reading items available in the system
enum ReadingItemType {
  guideline(label: 'Guideline', icon: '📋'),
  research(label: 'Research', icon: '🔬'),
  news(label: 'News', icon: '📰'),
  training(label: 'Training', icon: '📚'),
  protocol(label: 'Protocol', icon: '⚕️');

  const ReadingItemType({required this.label, required this.icon});

  final String label;
  final String icon;
}
