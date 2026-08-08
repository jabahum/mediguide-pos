import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/shared/models/models.dart';

void main() {
  test('clinical aggregate models map v2 relationship projections', () {
    final abbreviation = Abbreviation.fromJson({
      'id': 'abbr-1',
      'abbreviation': 'BP',
      'meaning': 'Blood pressure',
      'categories': ['Vitals'],
      'tags': ['Common'],
    });
    final drug = Drug.fromJson({
      'id': 'drug-1',
      'name': 'Amoxicillin',
      'route_of_administration': 'oral, IV',
      'pregnancy_category': 'B',
      'controlled_substance': 'Schedule II',
      'drug_class_id': 'class-1',
      'drug_class_name': 'Penicillin',
      'categories_json': ['Antibiotics'],
    });
    final guideline = Guideline.fromJson({
      'id': 'guideline-1',
      'condition_name': 'Hypertension',
      'categories': ['Cardiology'],
      'tags': ['NCD'],
      'index_item_id': 'index-1',
      'index_item_title': 'H',
    });

    expect(abbreviation.categoryName, 'Vitals');
    expect(abbreviation.tagNames, ['Common']);
    expect(drug.routeOfAdministration, [
      RouteOfAdministration.oral,
      RouteOfAdministration.iv,
    ]);
    expect(drug.pregnancyCategory, PregnancyCategory.b);
    expect(drug.controlledSubstance, ControlledSubstance.scheduleII);
    expect(drug.drugClass?.name, 'Penicillin');
    expect(guideline.categories.single.name, 'Cardiology');
    expect(guideline.indexItemTitle, 'H');
  });

  test('identity, support, conversation, and progress models are typed', () {
    final user = User.fromJson({
      'id': 'user-1',
      'preferred_language': 'en',
      'roles': [
        {'role_key': 'clinician'},
      ],
    });
    final ticket = SupportTicket.fromJson({
      'id': 'ticket-1',
      'status': 'in_progress',
      'priority': 'urgent',
      'user_id': 'user-1',
    });
    final message = Message.fromJson({
      'id': 'message-1',
      'sender_user_id': 'user-1',
      'message_type': 'text',
      'read_by': <String, dynamic>{},
      'reactions': <String, dynamic>{},
    });
    final progress = ReadingProgress.fromJson({
      'id': 'progress-1',
      'guideline_id': 'guideline-1',
      'progress_percentage': 0.5,
      'pending_sync': true,
    });

    expect(user.role, UserRole.healthcareProvider);
    expect(user.preferredLanguage, PreferredLanguage.english);
    expect(ticket.status, TicketStatus.inProgress);
    expect(ticket.isUrgent, isTrue);
    expect(message.senderUser?.id, 'user-1');
    expect(progress.pendingSync, isTrue);
    expect(progress.status, ReadingStatus.inProgress);
  });

  test('clinical taxonomy projections display names instead of UUIDs', () {
    const categoryId = '5cbdbadc-852e-5cd4-8e41-689f7aef1234';
    const tagId = '7c23aa4f-ec73-5f15-b84a-123456789abc';

    final drug = Drug.fromJson({
      'id': 'drug-1',
      'name': 'Amoxicillin',
      'categories_json': [categoryId],
      'category_details': [
        {'id': categoryId, 'name': 'Antibiotics'},
      ],
    });
    final guideline = Guideline.fromJson({
      'id': 'guideline-1',
      'condition_name': 'Ebola',
      'categories': [categoryId],
      'tags': [tagId],
      'category_details': [
        {'id': categoryId, 'name': 'Infectious diseases'},
      ],
      'tag_details': [
        {'id': tagId, 'name': 'Emergency'},
      ],
    });

    expect(drug.categories.single.name, 'Antibiotics');
    expect(guideline.categories.single.name, 'Infectious diseases');
    expect(guideline.tags.single.name, 'Emergency');

    expect(
      Drug.fromJson({
        'id': 'drug-2',
        'categories_json': [categoryId],
      }).categories,
      isEmpty,
    );
    expect(
      Guideline.fromJson({
        'id': 'guideline-2',
        'categories': [categoryId],
      }).categories,
      isEmpty,
    );
  });
}
