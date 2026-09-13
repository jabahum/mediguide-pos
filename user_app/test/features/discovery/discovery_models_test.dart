import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/discovery/data/models/discovery_models.dart';

void main() {
  test('discovery resources preserve reader and citation metadata', () {
    final resource = DiscoveryResource.fromJson(const {
      'id': 'resource-1',
      'content_type': 'guideline',
      'title': 'Malaria guidance',
      'route': '/guidelines/guideline-1',
      'issuing_authority': 'Ministry of Health',
      'version': '2.1',
      'publication_date': '2026-09-01T00:00:00Z',
      'effective_at': '2026-09-02T00:00:00Z',
      'review_at': '2027-09-01T00:00:00Z',
      'expires_at': '2028-09-01T00:00:00Z',
      'provenance': 'Official publication',
      'featured': true,
    });

    expect(resource.source, 'Ministry of Health');
    expect(resource.publicationDate, '2026-09-01T00:00:00Z');
    expect(resource.effectiveAt, isNotEmpty);
    expect(resource.reviewAt, isNotEmpty);
    expect(resource.expiresAt, isNotEmpty);
    expect(resource.provenance, 'Official publication');
    expect(resource.featured, isTrue);
  });

  test('hub parsing keeps diseases, nested pillars and featured items', () {
    final hub = DiscoveryHub.fromJson(const {
      'id': 'hub-1',
      'name': 'Ebola response hub',
      'slug': 'ebola-response',
      'diseases': [
        {'id': 'disease-1', 'name': 'Ebola virus disease', 'slug': 'ebola'},
      ],
      'pillars': [
        {
          'id': 'pillar-1',
          'name': 'Clinical care',
          'slug': 'clinical-care',
          'items': [
            {
              'featured': true,
              'resource': {
                'id': 'resource-1',
                'content_type': 'guideline',
                'title': 'Clinical guidance',
              },
            },
          ],
          'children': [
            {
              'id': 'pillar-2',
              'name': 'Triage',
              'slug': 'triage',
              'items': [],
              'children': [],
            },
          ],
        },
      ],
    });

    expect(hub.diseases.single.slug, 'ebola');
    expect(hub.pillars.single.resourceCount, 1);
    expect(hub.pillars.single.items.single.featured, isTrue);
    expect(hub.pillars.single.children.single.slug, 'triage');
  });
}
