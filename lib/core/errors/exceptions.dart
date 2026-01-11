/// Base exception for all app errors
abstract class AppException implements Exception {
  final String message;
  final String? details;

  AppException(this.message, [this.details]);

  @override
  String toString() =>
      'AppException: $message${details != null ? ' - $details' : ''}';
}

/// Network related errors
class NetworkException extends AppException {
  NetworkException(super.message, [super.details]);
}

/// Authentication errors
class AuthException extends AppException {
  AuthException(super.message, [super.details]);
}

/// API errors
class ApiException extends AppException {
  final int? statusCode;

  ApiException(super.message, [super.details, this.statusCode]);

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Database errors
class DatabaseException extends AppException {
  DatabaseException(super.message, [super.details]);
}
