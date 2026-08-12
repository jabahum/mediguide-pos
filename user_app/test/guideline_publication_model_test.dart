import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';

void main() {
  group('Guideline publication models', () {
    test('manifest uses the server-provided reader mode', () {
      final manifest = GuidelineManifest.fromJson(const {
        'guideline_id': 'guideline-1',
        'version_id': 'version-1',
        'recommended_mode': 'partial',
      });

      expect(manifest.recommendedMode, GuidelineReaderMode.partial);
    });

    test('unknown future block types use the safe fallback', () {
      final block = GuidelineBlock.fromJson(const {
        'kind': 'future_clinical_widget',
        'id': 'block-1',
        'sortOrder': 3,
        'rawType': 'future_clinical_widget',
        'raw': {'value': 'not rendered as clinical guidance'},
      });

      expect(block, isA<UnknownGuidelineBlock>());
      final unknown = block as UnknownGuidelineBlock;
      expect(unknown.rawType, 'future_clinical_widget');
      expect(unknown.raw['value'], 'not rendered as clinical guidance');
    });

    test('section blocks are returned in deterministic order', () {
      final content = GuidelinePublicationContent(
        publication: const GuidelinePublication(id: 'guideline-1'),
        manifest: const GuidelineManifest(
          guidelineId: 'guideline-1',
          versionId: 'version-1',
        ),
        sections: const [],
        blocks: const [
          GuidelineBlock.paragraph(
            id: 'second',
            sectionId: 'section-1',
            sortOrder: 2,
            text: 'Second',
          ),
          GuidelineBlock.paragraph(
            id: 'first',
            sectionId: 'section-1',
            sortOrder: 1,
            text: 'First',
          ),
        ],
      );

      expect(content.blocksFor('section-1').map((block) => block.id), [
        'first',
        'second',
      ]);
    });
  });
}
