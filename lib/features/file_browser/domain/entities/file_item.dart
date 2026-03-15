import 'package:equatable/equatable.dart';

class FileItem extends Equatable {
  const FileItem({
    required this.name,
    required this.path,
    required this.size,
    required this.createdAt,
    required this.modifiedAt,
    required this.isFolder,
  });

  final String name;
  final String path;
  final int size;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isFolder;

  @override
  List<Object?> get props =>
      <Object?>[name, path, size, createdAt, modifiedAt, isFolder];
}
