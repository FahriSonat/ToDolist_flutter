/// Uygulama içi hata sınıfları
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class AppDatabaseException extends AppException {
  final Object? originalError;
  const AppDatabaseException(super.message, [this.originalError]);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message);
}
