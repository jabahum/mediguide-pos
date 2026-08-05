import 'package:user_app/core/errors/app_exception.dart';

final class BackendApiException extends AppException {
  const BackendApiException(
    super.message, {
    required this.statusCode,
    this.retryAfter,
    super.cause,
  });

  final int statusCode;
  final Duration? retryAfter;

  bool get isRateLimited => statusCode == 429;

  @override
  String toString() {
    if (isRateLimited && retryAfter != null) {
      return '$message Try again in ${retryAfter!.inSeconds} seconds.';
    }
    return message;
  }
}
