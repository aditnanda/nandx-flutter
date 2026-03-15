import '../../../../features/smb_connections/domain/entities/smb_connection.dart';
import '../entities/file_item.dart';

typedef UploadProgressCallback = void Function(double progress);

abstract class FileRepository {
  Future<List<FileItem>> listFiles({
    required SmbConnection connection,
    required String path,
  });

  Future<void> deleteFile({
    required SmbConnection connection,
    required String path,
  });

  Future<void> uploadFile({
    required SmbConnection connection,
    required String targetDirectory,
    required String localFilePath,
    required String fileName,
    UploadProgressCallback? onProgress,
  });

  Future<void> createFolder({
    required SmbConnection connection,
    required String parentPath,
    required String folderName,
  });

  Future<void> createFile({
    required SmbConnection connection,
    required String parentPath,
    required String fileName,
  });
}
