import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/file_utils.dart';
import '../../domain/entities/file_item.dart';

class FileTile extends StatelessWidget {
  const FileTile({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final FileItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: Icon(item.isFolder
            ? Icons.folder_rounded
            : Icons.insert_drive_file_rounded),
        title: Text(item.name),
        subtitle: Text(
          item.isFolder
              ? 'Modified ${AppDateUtils.formatShort(item.modifiedAt)}'
              : '${FileUtils.humanReadableBytes(item.size)} • ${AppDateUtils.formatShort(item.modifiedAt)}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
