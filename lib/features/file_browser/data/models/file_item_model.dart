import '../../domain/entities/file_item.dart';

class FileItemModel extends FileItem {
  const FileItemModel({
    required super.name,
    required super.path,
    required super.size,
    required super.createdAt,
    required super.modifiedAt,
    required super.isFolder,
  });

  factory FileItemModel.fromEntity(FileItem entity) {
    return FileItemModel(
      name: entity.name,
      path: entity.path,
      size: entity.size,
      createdAt: entity.createdAt,
      modifiedAt: entity.modifiedAt,
      isFolder: entity.isFolder,
    );
  }

  FileItem toEntity() => FileItem(
        name: name,
        path: path,
        size: size,
        createdAt: createdAt,
        modifiedAt: modifiedAt,
        isFolder: isFolder,
      );
}
