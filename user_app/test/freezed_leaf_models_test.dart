import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/content/data/models/language_model.dart';
import 'package:user_app/features/notifications/data/models/my_notification.dart';
import 'package:user_app/features/support/data/models/faq.dart';
import 'package:user_app/features/support/data/models/support_ticket_reply.dart';

void main() {
  test('FAQ applies safe defaults and writes snake-case JSON', () {
    final faq = FAQ.fromJson({'id': 'faq-1', 'question': 'Where?'});

    expect(faq.priority, 'normal');
    expect(faq.tags, isEmpty);
    expect(faq.copyWith(answer: 'Here').answer, 'Here');
    expect(faq.toJson(), containsPair('is_featured', false));
    expect(FAQ.fromJson(faq.toJson()), faq);
  });

  test('language values have generated equality and immutable updates', () {
    final language = LanguageModel.fromJson({
      'id': 'sw',
      'code': 'sw',
      'name': 'Swahili',
      'native_name': 'Kiswahili',
      'version': 2,
      'unknown_server_field': true,
    });

    expect(language.displayName, 'Swahili (Kiswahili)');
    expect(language.version, 2);
    expect(language.copyWith(isDefault: true).isDefault, isTrue);
    expect(LanguageModel.fromJson(language.toJson()), language);
  });

  test('notification tolerates missing optional fields and timestamps', () {
    final notification = MyNotification.fromJson({
      'id': 'notice-1',
      'title': 'Update',
      'created_at': '',
    });

    expect(notification.isRead, isFalse);
    expect(notification.formattedDate, 'Unknown');
    expect(notification.copyWith(isRead: true).isRead, isTrue);
    expect(MyNotification.fromJson(notification.toJson()), notification);
  });

  test('support reply maps flattened author fields to a typed author', () {
    final reply = SupportTicketReply.fromJson({
      'id': 'reply-1',
      'ticket_id': 'ticket-1',
      'user_id': 'user-1',
      'user_name': 'Support Agent',
      'message': 'Resolved',
    });

    expect(reply.user?.name, 'Support Agent');
    expect(reply.authorInitials, 'SA');
    expect(reply.toJson()['user'], isA<Map<String, dynamic>>());
    expect(SupportTicketReply.fromJson(reply.toJson()), reply);
  });
}
