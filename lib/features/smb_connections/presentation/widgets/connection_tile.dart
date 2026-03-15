import 'package:flutter/material.dart';

import '../../domain/entities/smb_connection.dart';

class ConnectionTile extends StatelessWidget {
  const ConnectionTile({
    required this.connection,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isConnecting = false,
    super.key,
  });

  final SmbConnection connection;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: isConnecting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.storage_rounded),
        ),
        title: Text(connection.name),
        subtitle: Text(
            '${connection.host}:${connection.port}${connection.sharedPath}'),
        trailing: PopupMenuButton<String>(
          onSelected: (String value) {
            if (value == 'edit') {
              onEdit();
            } else {
              onDelete();
            }
          },
          itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
            PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
