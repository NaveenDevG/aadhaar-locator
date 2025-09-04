class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}

class AuthException extends AppException {
  const AuthException(String message, {String? code, dynamic details}) 
    : super(message, code: code, details: details);
}

class LocationException extends AppException {
  const LocationException(String message, {String? code, dynamic details}) 
    : super(message, code: code, details: details);
}

class NetworkException extends AppException {
  const NetworkException(String message, {String? code, dynamic details}) 
    : super(message, code: code, details: details);
}
