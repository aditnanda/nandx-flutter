import 'package:smb_connect/smb_connect.dart';

class SmbSessionService {
  final Map<String, SmbConnect> _sessions = <String, SmbConnect>{};

  SmbConnect? clientOf(String connectionId) => _sessions[connectionId];

  Future<bool> connect({
    required String connectionId,
    required String host,
    required String username,
    required String password,
    String domain = '',
  }) async {
    await disconnect(connectionId);

    try {
      final SmbConnect client = await SmbConnect.connectAuth(
        host: host,
        username: username,
        password: password,
        domain: domain,
      );
      _sessions[connectionId] = client;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect(String connectionId) async {
    final SmbConnect? existing = _sessions.remove(connectionId);
    if (existing != null) {
      await existing.close();
    }
  }

  Future<void> disconnectAll() async {
    final List<SmbConnect> sessions = _sessions.values.toList(growable: false);
    _sessions.clear();
    for (final SmbConnect session in sessions) {
      await session.close();
    }
  }
}
