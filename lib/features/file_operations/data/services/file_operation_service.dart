import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../file_browser/domain/repositories/file_repository.dart';
import '../../../smb_connections/domain/entities/smb_connection.dart';

class FileOperationService {
  FileOperationService(this._fileRepository);

  final FileRepository _fileRepository;

  Future<void> deleteFile(
      {required SmbConnection connection, required String path}) {
    return _fileRepository.deleteFile(connection: connection, path: path);
  }

  Future<void> uploadFile({
    required SmbConnection connection,
    required String targetDirectory,
    UploadProgressCallback? onProgress,
  }) async {
    final PermissionStatus storagePermission =
        await Permission.storage.request();
    if (!storagePermission.isGranted && !storagePermission.isLimited) {
      throw Exception('Storage permission is required for uploading files.');
    }

    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) {
      return;
    }

    final PlatformFile selected = result.files.single;
    await _fileRepository.uploadFile(
      connection: connection,
      targetDirectory: targetDirectory,
      localFilePath: selected.path!,
      fileName: selected.name,
      onProgress: onProgress,
    );
  }

  Future<void> createFolder({
    required SmbConnection connection,
    required String parentPath,
    required String folderName,
  }) {
    return _fileRepository.createFolder(
      connection: connection,
      parentPath: parentPath,
      folderName: folderName,
    );
  }

  Future<void> createFile({
    required SmbConnection connection,
    required String parentPath,
    required String fileName,
  }) {
    return _fileRepository.createFile(
      connection: connection,
      parentPath: parentPath,
      fileName: fileName,
    );
  }
}
