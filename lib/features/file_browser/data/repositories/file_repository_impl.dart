import 'dart:async';
import 'dart:io';

import 'package:smb_connect/smb_connect.dart';

import '../../../../core/services/smb_session_service.dart';
import '../../../smb_connections/domain/entities/smb_connection.dart';
import '../../domain/entities/file_item.dart';
import '../../domain/repositories/file_repository.dart';
import '../models/file_item_model.dart';

class FileRepositoryImpl implements FileRepository {
  FileRepositoryImpl(this._smbSessionService) {
    _seedMockFileSystem();
  }

  final SmbSessionService _smbSessionService;

  final Map<String, List<FileItemModel>> _fileTree =
      <String, List<FileItemModel>>{};

  @override
  Future<List<FileItem>> listFiles({
    required SmbConnection connection,
    required String path,
  }) async {
    final SmbConnect? client = _smbSessionService.clientOf(connection.id);
    if (client != null) {
      return _listRemoteFiles(client: client, path: _normalizePath(path));
    }

    await Future<void>.delayed(const Duration(milliseconds: 240));
    _ensurePath(path);

    final List<FileItemModel> nodes = _fileTree[path] ?? <FileItemModel>[];
    return nodes.map((FileItemModel e) => e.toEntity()).toList();
  }

  @override
  Future<void> deleteFile({
    required SmbConnection connection,
    required String path,
  }) async {
    final SmbConnect? client = _smbSessionService.clientOf(connection.id);
    if (client != null) {
      final SmbFile target = await client.file(_normalizePath(path));
      await client.delete(target);
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 160));

    final String parent = _parentPath(path);
    final List<FileItemModel>? siblings = _fileTree[parent];
    siblings?.removeWhere((FileItemModel element) => element.path == path);

    if (_fileTree.containsKey(path)) {
      final List<String> subtree = _fileTree.keys
          .where((String key) => key.startsWith('$path/'))
          .toList();
      for (final String key in subtree) {
        _fileTree.remove(key);
      }
      _fileTree.remove(path);
    }
  }

  @override
  Future<void> uploadFile({
    required SmbConnection connection,
    required String targetDirectory,
    required String localFilePath,
    required String fileName,
    UploadProgressCallback? onProgress,
  }) async {
    final SmbConnect? client = _smbSessionService.clientOf(connection.id);
    if (client != null) {
      final String remotePath = _joinPath(
        _normalizePath(targetDirectory),
        fileName,
      );
      final SmbFile remoteFile = await client.createFile(remotePath);
      final IOSink writer = await client.openWrite(remoteFile);

      final File localFile = File(localFilePath);
      final int totalSize = await localFile.length();
      int sent = 0;

      await for (final List<int> chunk in localFile.openRead()) {
        writer.add(chunk);
        sent += chunk.length;
        if (totalSize > 0) {
          onProgress?.call(sent / totalSize);
        }
      }

      await writer.flush();
      await writer.close();
      onProgress?.call(1);
      return;
    }

    _ensurePath(targetDirectory);

    for (int i = 1; i <= 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      onProgress?.call(i / 10);
    }

    final DateTime now = DateTime.now();
    final String newPath = _joinPath(targetDirectory, fileName);
    _fileTree[targetDirectory]!.removeWhere(
      (FileItemModel item) => item.path == newPath,
    );
    _fileTree[targetDirectory]!.add(
      FileItemModel(
        name: fileName,
        path: newPath,
        size: 3 * 1024 * 1024,
        createdAt: now,
        modifiedAt: now,
        isFolder: false,
      ),
    );
  }

  @override
  Future<void> createFolder({
    required SmbConnection connection,
    required String parentPath,
    required String folderName,
  }) async {
    final SmbConnect? client = _smbSessionService.clientOf(connection.id);
    if (client != null) {
      final String remotePath = _joinPath(
        _normalizePath(parentPath),
        folderName,
      );
      await client.createFolder(remotePath);
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 140));
    _ensurePath(parentPath);

    final DateTime now = DateTime.now();
    final String folderPath = _joinPath(parentPath, folderName);

    _fileTree[parentPath]!.removeWhere(
      (FileItemModel item) => item.path == folderPath,
    );
    _fileTree[parentPath]!.add(
      FileItemModel(
        name: folderName,
        path: folderPath,
        size: 0,
        createdAt: now,
        modifiedAt: now,
        isFolder: true,
      ),
    );

    _fileTree.putIfAbsent(folderPath, () => <FileItemModel>[]);
  }

  @override
  Future<void> createFile({
    required SmbConnection connection,
    required String parentPath,
    required String fileName,
  }) async {
    final SmbConnect? client = _smbSessionService.clientOf(connection.id);
    if (client != null) {
      final String remotePath = _joinPath(_normalizePath(parentPath), fileName);
      await client.createFile(remotePath);
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 140));
    _ensurePath(parentPath);

    final DateTime now = DateTime.now();
    final String filePath = _joinPath(parentPath, fileName);

    _fileTree[parentPath]!.removeWhere(
      (FileItemModel item) => item.path == filePath,
    );
    _fileTree[parentPath]!.add(
      FileItemModel(
        name: fileName,
        path: filePath,
        size: 0,
        createdAt: now,
        modifiedAt: now,
        isFolder: false,
      ),
    );
  }

  Future<List<FileItem>> _listRemoteFiles({
    required SmbConnect client,
    required String path,
  }) async {
    if (path == '/') {
      final List<SmbFile> shares = await client.listShares();
      return shares
          .map((SmbFile share) => _mapSmbFile(share, isFolderOverride: true))
          .toList(growable: false);
    }

    final SmbFile folder = await client.file(path);
    final List<SmbFile> remoteFiles = await client.listFiles(folder);

    return remoteFiles
        .map((SmbFile item) => _mapSmbFile(item))
        .toList(growable: false);
  }

  FileItem _mapSmbFile(SmbFile smbFile, {bool? isFolderOverride}) {
    final DateTime now = DateTime.now();
    final bool isFolder = isFolderOverride ?? smbFile.isDirectory();

    return FileItem(
      name: smbFile.name,
      path: _normalizePath(smbFile.path),
      size: smbFile.size,
      createdAt: _fromSmbTime(smbFile.createTime, fallback: now),
      modifiedAt: _fromSmbTime(smbFile.lastModified, fallback: now),
      isFolder: isFolder,
    );
  }

  DateTime _fromSmbTime(int value, {required DateTime fallback}) {
    if (value <= 0) {
      return fallback;
    }

    try {
      final DateTime date = DateTime.fromMillisecondsSinceEpoch(
        value,
        isUtc: true,
      ).toLocal();
      if (date.year < 1980 || date.year > 3000) {
        return fallback;
      }
      return date;
    } catch (_) {
      return fallback;
    }
  }

  String _normalizePath(String path) {
    if (path.isEmpty) {
      return '/';
    }

    String normalized = path;
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }

    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  void _seedMockFileSystem() {
    final DateTime now = DateTime.now();

    _fileTree['/'] = <FileItemModel>[
      FileItemModel(
        name: 'Movies',
        path: '/Movies',
        size: 0,
        createdAt: now.subtract(const Duration(days: 90)),
        modifiedAt: now.subtract(const Duration(days: 2)),
        isFolder: true,
      ),
      FileItemModel(
        name: 'Downloads',
        path: '/Downloads',
        size: 0,
        createdAt: now.subtract(const Duration(days: 30)),
        modifiedAt: now.subtract(const Duration(days: 1)),
        isFolder: true,
      ),
      FileItemModel(
        name: 'Readme.txt',
        path: '/Readme.txt',
        size: 1520,
        createdAt: now.subtract(const Duration(days: 5)),
        modifiedAt: now.subtract(const Duration(days: 5)),
        isFolder: false,
      ),
    ];

    _fileTree['/Movies'] = <FileItemModel>[
      FileItemModel(
        name: 'BigBuckBunny.mp4',
        path: '/Movies/BigBuckBunny.mp4',
        size: 250 * 1024 * 1024,
        createdAt: now.subtract(const Duration(days: 10)),
        modifiedAt: now.subtract(const Duration(days: 3)),
        isFolder: false,
      ),
      FileItemModel(
        name: 'BigBuckBunny.srt',
        path: '/Movies/BigBuckBunny.srt',
        size: 62 * 1024,
        createdAt: now.subtract(const Duration(days: 10)),
        modifiedAt: now.subtract(const Duration(days: 3)),
        isFolder: false,
      ),
      FileItemModel(
        name: 'NatureShow.mkv',
        path: '/Movies/NatureShow.mkv',
        size: 840 * 1024 * 1024,
        createdAt: now.subtract(const Duration(days: 2)),
        modifiedAt: now.subtract(const Duration(days: 1)),
        isFolder: false,
      ),
    ];

    _fileTree['/Downloads'] = <FileItemModel>[];
  }

  void _ensurePath(String path) {
    _fileTree.putIfAbsent(path, () => <FileItemModel>[]);
  }

  String _parentPath(String path) {
    if (path == '/' || !path.contains('/')) {
      return '/';
    }

    final int index = path.lastIndexOf('/');
    if (index <= 0) {
      return '/';
    }

    return path.substring(0, index);
  }

  String _joinPath(String parent, String name) {
    if (parent == '/') {
      return '/$name';
    }
    return '$parent/$name';
  }
}
