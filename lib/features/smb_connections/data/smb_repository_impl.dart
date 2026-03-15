import 'dart:convert';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/smb_session_service.dart';
import '../domain/entities/smb_connection.dart';
import '../domain/smb_repository.dart';
import 'smb_connection_model.dart';

class SmbRepositoryImpl implements SmbRepository {
  SmbRepositoryImpl(this._storageService, this._smbSessionService);

  final SecureStorageService _storageService;
  final SmbSessionService _smbSessionService;

  @override
  Future<List<SmbConnection>> getConnections() async {
    final String? raw = await _storageService.read(
      AppConstants.smbConnectionsKey,
    );
    if (raw == null || raw.isEmpty) {
      return <SmbConnection>[];
    }

    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (dynamic item) => SmbConnectionModel.fromJson(
            item as Map<String, dynamic>,
          ).toEntity(),
        )
        .toList();
  }

  @override
  Future<void> saveConnection(
    SmbConnection connection, {
    String? password,
  }) async {
    await _smbSessionService.disconnect(connection.id);

    final List<SmbConnection> current = await getConnections();
    final int index = current.indexWhere(
      (SmbConnection e) => e.id == connection.id,
    );

    if (index >= 0) {
      current[index] = connection;
    } else {
      current.add(connection);
    }

    final List<Map<String, dynamic>> payload = current
        .map((SmbConnection e) => SmbConnectionModel.fromEntity(e).toJson())
        .toList();

    await _storageService.writeJson(
      key: AppConstants.smbConnectionsKey,
      data: payload,
    );

    if (password != null && password.isNotEmpty) {
      await _storageService.write(
        key: '${AppConstants.smbPasswordPrefix}${connection.id}',
        value: password,
      );
    }
  }

  @override
  Future<void> deleteConnection(String id) async {
    final List<SmbConnection> current = await getConnections();
    current.removeWhere((SmbConnection element) => element.id == id);

    final List<Map<String, dynamic>> payload = current
        .map((SmbConnection e) => SmbConnectionModel.fromEntity(e).toJson())
        .toList();

    await _storageService.writeJson(
      key: AppConstants.smbConnectionsKey,
      data: payload,
    );
    await _storageService.delete('${AppConstants.smbPasswordPrefix}$id');
    await _smbSessionService.disconnect(id);
  }

  @override
  Future<SmbConnection?> getConnection(String id) async {
    final List<SmbConnection> all = await getConnections();
    return all.where((SmbConnection e) => e.id == id).firstOrNull;
  }

  @override
  Future<String?> getPassword(String id) {
    return _storageService.read('${AppConstants.smbPasswordPrefix}$id');
  }

  @override
  Future<bool> connect(SmbConnection connection) async {
    final String password = await getPassword(connection.id) ?? '';
    final String username = _resolveUsername(connection.username);
    final String domain = _resolveDomain(connection.username);

    return _smbSessionService.connect(
      connectionId: connection.id,
      host: connection.host,
      username: username,
      password: password,
      domain: domain,
    );
  }

  String _resolveUsername(String usernameInput) {
    if (!usernameInput.contains('\\')) {
      return usernameInput.trim();
    }

    final List<String> parts = usernameInput.split('\\');
    if (parts.length < 2) {
      return usernameInput.trim();
    }

    final String username = parts.sublist(1).join('\\').trim();
    return username.isEmpty ? usernameInput.trim() : username;
  }

  String _resolveDomain(String usernameInput) {
    if (!usernameInput.contains('\\')) {
      return '';
    }

    final List<String> parts = usernameInput.split('\\');
    if (parts.isEmpty) {
      return '';
    }
    return parts.first.trim();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
