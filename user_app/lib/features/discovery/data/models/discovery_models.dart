final class DiscoveryResource {
  const DiscoveryResource({
    required this.id,
    required this.contentType,
    required this.title,
    this.description = '',
    this.route = '',
    this.source = '',
    this.version = '',
    this.publicationDate = '',
    this.effectiveAt = '',
    this.reviewAt = '',
    this.expiresAt = '',
    this.provenance = '',
    this.featured = false,
  });
  final String id, contentType, title, description, route, source, version;
  final String publicationDate, effectiveAt, reviewAt, expiresAt, provenance;
  final bool featured;
  factory DiscoveryResource.fromJson(Map<String, dynamic> json) =>
      DiscoveryResource(
        id: '${json['id'] ?? ''}',
        contentType: '${json['content_type'] ?? ''}',
        title: '${json['title'] ?? ''}',
        description: '${json['description'] ?? ''}',
        route: '${json['route'] ?? ''}',
        source:
            '${json['issuing_authority'] ?? json['source_organization'] ?? ''}',
        version: '${json['version'] ?? ''}',
        publicationDate: '${json['publication_date'] ?? ''}',
        effectiveAt: '${json['effective_at'] ?? ''}',
        reviewAt: '${json['review_at'] ?? ''}',
        expiresAt: '${json['expires_at'] ?? ''}',
        provenance: '${json['provenance'] ?? ''}',
        featured: json['featured'] == true,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'content_type': contentType,
    'title': title,
    'description': description,
    'route': route,
    'source_organization': source,
    'version': version,
    'publication_date': publicationDate,
    'effective_at': effectiveAt,
    'review_at': reviewAt,
    'expires_at': expiresAt,
    'provenance': provenance,
    'featured': featured,
  };
}

final class DiscoveryDisease {
  const DiscoveryDisease({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId = '',
    this.description = '',
    this.aliases = const [],
    this.children = const [],
    this.hubs = const [],
    this.resources = const [],
  });
  final String id, name, slug, parentId, description;
  final List<String> aliases;
  final List<DiscoveryDisease> children;
  final List<DiscoveryHub> hubs;
  final List<DiscoveryResource> resources;
  factory DiscoveryDisease.fromJson(
    Map<String, dynamic> json,
  ) => DiscoveryDisease(
    id: '${json['id'] ?? ''}',
    name: '${json['name'] ?? ''}',
    slug: '${json['slug'] ?? ''}',
    parentId: '${json['parent_id'] ?? ''}',
    description: '${json['description'] ?? ''}',
    aliases: (json['aliases'] as List? ?? const []).map((e) => '$e').toList(),
    children: _maps(json['children']).map(DiscoveryDisease.fromJson).toList(),
    hubs: _maps(json['hubs']).map(DiscoveryHub.fromJson).toList(),
    resources: _maps(
      json['resources'],
    ).map(DiscoveryResource.fromJson).toList(),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'parent_id': parentId,
    'description': description,
    'aliases': aliases,
    'children': children.map((e) => e.toJson()).toList(),
    'hubs': hubs.map((e) => e.toJson()).toList(),
    'resources': resources.map((e) => e.toJson()).toList(),
  };
}

final class DiscoveryPillar {
  const DiscoveryPillar({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.icon = '',
    this.items = const [],
    this.children = const [],
  });
  final String id, name, slug, description, icon;
  final List<DiscoveryResource> items;
  final List<DiscoveryPillar> children;
  factory DiscoveryPillar.fromJson(Map<String, dynamic> json) =>
      DiscoveryPillar(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        slug: '${json['slug'] ?? ''}',
        description: '${json['description'] ?? ''}',
        icon: '${json['icon'] ?? ''}',
        items: _maps(json['items'])
            .map(
              (item) => item['resource'] is Map
                  ? DiscoveryResource.fromJson({
                      ...Map<String, dynamic>.from(item['resource'] as Map),
                      'featured': item['featured'] == true,
                    })
                  : null,
            )
            .whereType<DiscoveryResource>()
            .toList(),
        children: _maps(
          json['children'],
        ).map(DiscoveryPillar.fromJson).toList(),
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'icon': icon,
    'items': items.map((e) => {'resource': e.toJson()}).toList(),
    'children': children.map((e) => e.toJson()).toList(),
  };
  int get resourceCount =>
      items.length +
      children.fold(0, (sum, child) => sum + child.resourceCount);
}

final class DiscoveryHub {
  const DiscoveryHub({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.outbreak,
    this.diseases = const [],
    this.pillars = const [],
  });
  final String id, name, slug, description;
  final Map<String, dynamic>? outbreak;
  final List<DiscoveryDisease> diseases;
  final List<DiscoveryPillar> pillars;
  factory DiscoveryHub.fromJson(Map<String, dynamic> json) => DiscoveryHub(
    id: '${json['id'] ?? ''}',
    name: '${json['name'] ?? ''}',
    slug: '${json['slug'] ?? ''}',
    description: '${json['description'] ?? ''}',
    outbreak: json['outbreak'] is Map
        ? Map<String, dynamic>.from(json['outbreak'] as Map)
        : null,
    diseases: _maps(json['diseases']).map(DiscoveryDisease.fromJson).toList(),
    pillars: _maps(json['pillars']).map(DiscoveryPillar.fromJson).toList(),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'outbreak': outbreak,
    'diseases': diseases.map((e) => e.toJson()).toList(),
    'pillars': pillars.map((e) => e.toJson()).toList(),
  };
}

final class DiscoveryValue<T> {
  const DiscoveryValue(this.value, {this.offline = false});
  final T value;
  final bool offline;
}

List<Map<String, dynamic>> _maps(dynamic value) => (value as List? ?? const [])
    .whereType<Map>()
    .map((e) => Map<String, dynamic>.from(e))
    .toList();
