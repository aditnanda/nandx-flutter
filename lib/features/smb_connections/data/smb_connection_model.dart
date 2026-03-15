import '../domain/entities/smb_connection.dart';

class SmbConnectionModel extends SmbConnection {
  const SmbConnectionModel({
    required super.id,
    required super.name,
    required super.host,
    required super.port,
    required super.username,
    required super.sharedPath,
    super.password,
  });

  factory SmbConnectionModel.fromJson(Map<String, dynamic> json) {
    return SmbConnectionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int,
      username: json['username'] as String,
      sharedPath: json['sharedPath'] as String,
    );
  }

  factory SmbConnectionModel.fromEntity(SmbConnection entity) {
    return SmbConnectionModel(
      id: entity.id,
      name: entity.name,
      host: entity.host,
      port: entity.port,
      username: entity.username,
      sharedPath: entity.sharedPath,
      password: entity.password,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'sharedPath': sharedPath,
    };
  }

  SmbConnection toEntity() {
    return SmbConnection(
      id: id,
      name: name,
      host: host,
      port: port,
      username: username,
      sharedPath: sharedPath,
      password: password,
    );
  }
}
