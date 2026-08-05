import 'package:user_app/core/errors/app_exception.dart';
import 'package:user_app/core/errors/failure.dart';

abstract final class ErrorHandler {
  static Failure toFailure(Object error) {
    if (error is AppException) {
      return Failure(error.message, cause: error.cause ?? error);
    }
    return Failure('An unexpected error occurred.', cause: error);
  }
}
