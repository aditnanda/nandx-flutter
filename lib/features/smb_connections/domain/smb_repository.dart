import 'entities/smb_connection.dart';

abstract class SmbRepository {
  Future<List<SmbConnection>> getConnections();
  Future<void> saveConnection(SmbConnection connection, {String? password});
  Future<void> deleteConnection(String id);
  Future<SmbConnection?> getConnection(String id);
  Future<String?> getPassword(String id);

  /// Placeholder contract for actual SMB SDK integration.
  Future<bool> connect(SmbConnection connection);
}
