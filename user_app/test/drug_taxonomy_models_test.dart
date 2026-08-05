import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/drugs/data/models/drug_category.dart';
import 'package:user_app/features/drugs/data/models/drug_class.dart';
import 'package:user_app/features/drugs/data/models/drug_tag.dart';
import 'package:user_app/features/drugs/data/models/therapeutic_category.dart';
import 'package:user_app/shared/models/common_enums.dart';

void main() {
  test('drug category maps parent and unknown status', () {
    final category = DrugCategory.fromJson({
      'id': 'category-1',
      'name': 'Antimicrobials',
      'parent_category_id': 'category-root',
      'sort_order': 2,
      'status': 'new-status',
    });

    expect(category.hasParent, isTrue);
    expect(category.status, Status.unknown);
    expect(DrugCategory.fromJson(category.toJson()), category);
  });

  test('drug reference records serialize snake-case fields', () {
    const drugClass = DrugClass(id: 'class-1', name: 'Beta blockers');
    const tag = DrugTag(
      id: 'tag-1',
      name: 'First line',
      tagCategory: 'treatment',
    );
    const therapeutic = TherapeuticCategory(
      id: 'therapy-1',
      name: 'Cardiovascular',
    );

    expect(tag.toJson()['tag_category'], 'treatment');
    expect(drugClass.copyWith(name: 'ACE inhibitors').name, 'ACE inhibitors');
    expect(TherapeuticCategory.fromJson(therapeutic.toJson()), therapeutic);
  });

  test('drug create request omits absent fields', () {
    const request = CreateDrugCategoryRequest(name: 'Antimicrobials');
    expect(request.toJson(), {'name': 'Antimicrobials'});
  });
}
