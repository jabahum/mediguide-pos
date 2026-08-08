import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/consultants/data/repositories/consultant_local_repository.dart';
import 'package:user_app/features/consultants/data/repositories/consultant_repository.dart';
import 'package:user_app/features/conversations/data/repositories/conversation_local_repository.dart';
import 'package:user_app/features/conversations/data/repositories/conversation_repository.dart';
import 'package:user_app/features/facilities/data/repositories/facility_local_repository.dart';
import 'package:user_app/features/facilities/data/repositories/facility_repository.dart';

import 'helpers/test_local_store.dart';

final class OfflineDirectoryApi extends BackendApiService {
  bool offline = false;
  Map<String, String>? lastQuery;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    lastQuery = query;
    if (offline) throw StateError('offline');

    if (path == '/api/v2/facilities') {
      return {
        'data': {
          'items': [_facility],
          'page': 1,
          'per_page': 20,
          'total_items': 1,
          'total_pages': 1,
        },
      };
    }
    if (path == '/api/v2/facilities/facility-1') {
      return {'data': _facility};
    }
    if (path == '/api/v2/consultants') {
      return {
        'data': {
          'items': [_consultant],
          'page': 1,
          'per_page': 20,
          'total_items': 1,
          'total_pages': 1,
        },
      };
    }
    if (path == '/api/v2/consultants/consultant-1') {
      return {'data': _consultant};
    }
    if (path == '/api/v2/conversations') {
      return {
        'data': {
          'items': [_olderConversation, _newerConversation],
          'page': 1,
          'per_page': 20,
          'total_items': 2,
          'total_pages': 1,
        },
      };
    }
    if (path == '/api/v2/conversations/conversation-new') {
      return {'data': _newerConversation};
    }
    if (path == '/api/v2/conversations/conversation-new/messages') {
      return {
        'data': {
          'items': [_laterMessage, _earlierMessage],
          'page': 1,
          'per_page': 100,
          'total_items': 2,
          'total_pages': 1,
        },
      };
    }
    throw StateError('Unexpected request: $method $path');
  }
}

const _facility = <String, dynamic>{
  'id': 'facility-1',
  'name': 'Central Hospital',
  'region_id': 'region-1',
  'region_name': 'Central',
  'district_id': 'district-1',
  'district_name': 'Kampala',
  'facility_level_id': 'level-1',
  'ownership_type_id': 'owner-1',
  'updated_at': '2026-08-01T00:00:00Z',
};

const _consultant = <String, dynamic>{
  'id': 'consultant-1',
  'name': 'Dr Amina',
  'email': 'amina@example.test',
  'specialty': 'Cardiology',
  'qualifications': ['Specialist'],
  'preferred_language': 'English',
  'consultation_types': ['Telemedicine'],
  'region': 'Central',
  'city': 'Kampala',
  'status': 'active',
  'is_verified': true,
  'rating': 4.8,
  'updated_at': '2026-08-01T00:00:00Z',
};

const _olderConversation = <String, dynamic>{
  'id': 'conversation-old',
  'participant1_user_id': 'user-1',
  'participant2_user_id': 'doctor-1',
  'participant2_name': 'Dr Old',
  'last_activity': '2026-08-01T08:00:00Z',
};

const _newerConversation = <String, dynamic>{
  'id': 'conversation-new',
  'participant1_user_id': 'user-1',
  'participant2_user_id': 'doctor-2',
  'participant2_name': 'Dr New',
  'last_activity': '2026-08-02T08:00:00Z',
};

const _earlierMessage = <String, dynamic>{
  'id': 'message-1',
  'conversation_id': 'conversation-new',
  'sender_user_id': 'user-1',
  'content': 'First',
  'message_type': 'text',
  'created_at': '2026-08-02T08:00:00Z',
};

const _laterMessage = <String, dynamic>{
  'id': 'message-2',
  'conversation_id': 'conversation-new',
  'sender_user_id': 'doctor-2',
  'content': 'Second',
  'message_type': 'text',
  'created_at': '2026-08-02T08:01:00Z',
};

void main() {
  test(
    'facilities cache remote list and detail with typed offline filters',
    () async {
      final api = OfflineDirectoryApi();
      final store = TestLocalStore();
      addTearDown(store.close);
      final repository = FacilityRepository(
        api,
        FacilityLocalRepository(store.cache),
      );

      await repository.listFacilities(
        page: 1,
        perPage: 20,
        regionId: 'region-1',
        districtId: 'district-1',
      );
      expect(api.lastQuery?['region_id'], 'region-1');
      expect(api.lastQuery?['district_id'], 'district-1');

      api.offline = true;
      final cached = await repository.listFacilities(
        page: 1,
        perPage: 20,
        search: 'central',
        regionId: 'region-1',
        districtId: 'district-1',
        facilityLevelId: 'level-1',
        ownershipTypeId: 'owner-1',
      );

      expect(cached.items.single.id, 'facility-1');
      expect(
        (await repository.facility('facility-1')).name,
        'Central Hospital',
      );
    },
  );

  test(
    'consultants cache list and detail with equivalent typed filters',
    () async {
      final api = OfflineDirectoryApi();
      final store = TestLocalStore();
      addTearDown(store.close);
      final repository = ConsultantRepository(
        api,
        ConsultantLocalRepository(store.cache),
      );

      await repository.list(
        specialty: 'Cardiology',
        qualification: 'Specialist',
        language: 'English',
        consultationType: 'Telemedicine',
        status: 'active',
        verified: true,
      );
      expect(api.lastQuery?['qualification'], 'Specialist');
      expect(api.lastQuery?['consultation_type'], 'Telemedicine');

      api.offline = true;
      final cached = await repository.list(
        search: 'amina',
        specialty: 'Cardiology',
        qualification: 'Specialist',
        language: 'English',
        region: 'Central',
        city: 'Kampala',
        consultationType: 'Telemedicine',
        status: 'active',
        verified: true,
      );

      expect(cached.items.single.id, 'consultant-1');
      expect((await repository.get('consultant-1')).name, 'Dr Amina');
    },
  );

  test(
    'conversation cache is user scoped and messages are chronological',
    () async {
      final api = OfflineDirectoryApi();
      final store = TestLocalStore();
      addTearDown(store.close);
      final local = ConversationLocalRepository(store.cache);
      final repository = ConversationRepository(api, local, userId: 'user-1');

      await repository.list();
      await repository.get('conversation-new');
      await repository.messages('conversation-new');

      api.offline = true;
      final conversations = await repository.list();
      final messages = await repository.messages('conversation-new');

      expect(conversations.items.map((item) => item.id), [
        'conversation-new',
        'conversation-old',
      ]);
      expect(messages.items.map((item) => item.content), ['First', 'Second']);
      expect((await repository.get('conversation-new')).id, 'conversation-new');

      final otherUser = ConversationRepository(api, local, userId: 'user-2');
      await expectLater(otherUser.list(), throwsA(isA<StateError>()));
    },
  );
}
