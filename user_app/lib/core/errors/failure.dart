final class Failure {
  const Failure(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;
}
