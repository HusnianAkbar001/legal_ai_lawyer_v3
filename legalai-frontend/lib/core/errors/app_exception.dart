class AppException implements Exception {
  final String userMessage;
  final int? statusCode;
  final Object? cause;

  AppException({
    required this.userMessage,
    this.statusCode,
    this.cause,
  });

  @override
  String toString() {
    return userMessage;
  }
}
