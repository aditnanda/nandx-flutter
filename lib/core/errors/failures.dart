import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message);
}

class SmbFailure extends Failure {
  const SmbFailure(super.message);
}

class FileOperationFailure extends Failure {
  const FileOperationFailure(super.message);
}
