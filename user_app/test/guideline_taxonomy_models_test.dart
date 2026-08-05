import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/guidelines/data/models/guideline_category.dart';
import 'package:user_app/features/guidelines/data/models/guideline_index.dart';
import 'package:user_app/features/guidelines/data/models/guideline_tag.dart';

void main() {
  test('guideline category maps hierarchy, timestamps, and unknown status', () {
    final category = GuidelineCategory.fromJson({
      'id': 'category-1',
      'name': 'Emergency care',
      'parent_category_id': 'parent-1',
      'parent_name': 'Clinical care',
      'sort_order': 2,
      'status': 'future-status',
      'created_at': '2026-08-05T07:00:00Z',
      'extra_backend_field': true,
    });

    expect(category.hasParent, isTrue);
    expect(category.status, GuidelineCategoryStatus.unknown);
    expect(category.createdAt, DateTime.utc(2026, 8, 5, 7));
    expect(category.copyWith(name: 'Triage').name, 'Triage');
    expect(GuidelineCategory.fromJson(category.toJson()), category);
  });

  test('guideline tag has value equality and safe defaults', () {
    const first = GuidelineTag(id: 'tag-1', name: 'Paediatrics');
    const second = GuidelineTag(id: 'tag-1', name: 'Paediatrics');

    expect(first, second);
    expect(first.hasDescription, isFalse);
    expect(GuidelineTag.fromJson(first.toJson()), first);
  });

  test('guideline index maps typed parent fields without expand data', () {
    final index = GuidelineIndex.fromJson({
      'id': 'index-2',
      'title': 'Triage',
      'parent_id': 'index-1',
      'parent_title': 'Red Channel',
      'sort_order': 4,
      'has_children': true,
    });

    expect(index.hasParent, isTrue);
    expect(index.isRedBranch, isTrue);
    expect(index.order, 4);
    expect(GuidelineIndex.fromJson(index.toJson()), index);
  });

  test('create requests omit absent optional fields', () {
    const request = CreateGuidelineCategoryRequest(name: 'Emergency care');

    expect(request.toJson(), {'name': 'Emergency care'});
  });
}
