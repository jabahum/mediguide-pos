import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated_response.freezed.dart';
part 'paginated_response.g.dart';

@Freezed(genericArgumentFactories: true, makeCollectionsUnmodifiable: true)
abstract class PaginatedResponse<T> with _$PaginatedResponse<T> {
  const factory PaginatedResponse({
    @Default([]) List<T> items,
    @Default(1) int page,
    @JsonKey(name: 'per_page') @Default(20) int perPage,
    @JsonKey(name: 'total_items') @Default(0) int totalItems,
    @JsonKey(name: 'total_pages') @Default(0) int totalPages,
  }) = _PaginatedResponse<T>;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PaginatedResponseFromJson(json, fromJsonT);
}
