import 'package:flutter/material.dart';

class FileActionMenu extends StatelessWidget {
  const FileActionMenu({
    required this.onDelete,
    required this.onUpload,
    required this.onCreateFolder,
    required this.onCreateFile,
    super.key,
  });

  final VoidCallback onDelete;
  final VoidCallback onUpload;
  final VoidCallback onCreateFolder;
  final VoidCallback onCreateFile;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete'),
              onTap: onDelete,
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Upload File'),
              onTap: onUpload,
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('Create Folder'),
              onTap: onCreateFolder,
            ),
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('Create New File'),
              onTap: onCreateFile,
            ),
          ],
        ),
      ),
    );
  }
}
