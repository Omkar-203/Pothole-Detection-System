class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;
  ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message, body: $body)';
}
