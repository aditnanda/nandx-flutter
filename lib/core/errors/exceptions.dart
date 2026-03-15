class AppException implements Exception {
  AppException(this.message);

  final String message;

  @override
  String toString() => 'AppException(message: $message)';
}

class StorageException extends AppException {
  StorageException(super.message);
}

class AuthenticationException extends AppException {
  AuthenticationException(super.message);
}

class SmbException extends AppException {
  SmbException(super.message);
}

class FileOperationException extends AppException {
  FileOperationException(super.message);
}
