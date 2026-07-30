import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/app/data/models/api_record.dart';

void main() {
  group('ApiRecord', () {
    test('exposes common fields and serializes without SDK types', () {
      final record = ApiRecord({
        'id': 'record-1',
        'collectionId': 'collection-1',
        'collectionName': 'guidelines',
        'created': '2026-07-30T12:00:00Z',
        'updated': '2026-07-30T13:00:00Z',
        'title': 'Emergency care',
      });

      expect(record.id, 'record-1');
      expect(record.collectionId, 'collection-1');
      expect(record.collectionName, 'guidelines');
      expect(record.get<String>('title'), 'Emergency care');
      expect(record.toJson(), containsPair('id', 'record-1'));
    });

    test('supports numeric and list conversions used by app models', () {
      final record = ApiRecord({
        'score': 4,
        'tags': <dynamic>['urgent', 2],
      });

      expect(record.get<double>('score'), 4.0);
      expect(record.get<List<String>>('tags', <String>[]), ['urgent', '2']);
      expect(record.get<String>('missing', 'fallback'), 'fallback');
    });
  });

  test('PagedResult retains pagination metadata and items', () {
    final result = PagedResult<ApiRecord>(
      page: 2,
      perPage: 10,
      totalItems: 21,
      totalPages: 3,
      items: [
        ApiRecord({'id': 'record-11'}),
      ],
    );

    expect(result.page, 2);
    expect(result.perPage, 10);
    expect(result.totalItems, 21);
    expect(result.totalPages, 3);
    expect(result.items.single.id, 'record-11');
  });
}
