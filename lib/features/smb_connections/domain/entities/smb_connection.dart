import 'package:equatable/equatable.dart';

class SmbConnection extends Equatable {
  const SmbConnection({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.sharedPath,
    this.password,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String sharedPath;
  final String? password;

  SmbConnection copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? sharedPath,
    String? password,
  }) {
    return SmbConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      sharedPath: sharedPath ?? this.sharedPath,
      password: password ?? this.password,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[id, name, host, port, username, sharedPath, password];
}
