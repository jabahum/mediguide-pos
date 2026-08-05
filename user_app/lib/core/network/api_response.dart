final class ApiResponse<T> {
  const ApiResponse({required this.data, this.message, this.requestId});

  final T data;
  final String? message;
  final String? requestId;
}
