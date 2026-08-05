class TreeSelectorConfig {
  final String title;
  final String endpointPath;
  final Map<String, dynamic> context;
  final bool allowParentSelection;
  final bool barrierDismissible;

  const TreeSelectorConfig({
    required this.title,
    required this.endpointPath,
    this.context = const <String, dynamic>{},
    this.allowParentSelection = false,
    this.barrierDismissible = true,
  });
}

class TreeSelectorNodeModel {
  final String id;
  final String title;
  final String subtitle;
  final int level;
  final int count;
  final bool hasChildren;
  final Map<String, dynamic> filters;

  const TreeSelectorNodeModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.count,
    required this.hasChildren,
    required this.filters,
  });

  factory TreeSelectorNodeModel.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? json['label'] ?? json['name'] ?? '')
        .toString();
    final id = (json['id'] ?? json['value'] ?? title).toString();
    final subtitle = (json['subtitle'] ?? json['description'] ?? '').toString();
    final level = _toInt(json['level']);
    final count = _toInt(json['count']);
    final hasChildren =
        _toBool(json['hasChildren']) ||
        _toInt(json['childrenCount']) > 0 ||
        _toInt(json['children_count']) > 0;
    final filtersRaw = json['filters'];
    final filters = filtersRaw is Map
        ? Map<String, dynamic>.from(filtersRaw)
        : <String, dynamic>{};

    return TreeSelectorNodeModel(
      id: id,
      title: title,
      subtitle: subtitle,
      level: level,
      count: count,
      hasChildren: hasChildren,
      filters: filters,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value.toInt() != 0;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
}

class TreeSelectionResult {
  final TreeSelectorNodeModel selectedNode;
  final Map<String, dynamic> filters;

  const TreeSelectionResult({
    required this.selectedNode,
    required this.filters,
  });
}
