import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../smb_connections/domain/entities/smb_connection.dart';
import '../../data/services/file_operation_service.dart';

class FileOperationState extends Equatable {
  const FileOperationState({
    required this.isProcessing,
    required this.progress,
    this.errorMessage,
  });

  const FileOperationState.initial()
      : isProcessing = false,
        progress = 0,
        errorMessage = null;

  final bool isProcessing;
  final double progress;
  final String? errorMessage;

  FileOperationState copyWith({
    bool? isProcessing,
    double? progress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FileOperationState(
      isProcessing: isProcessing ?? this.isProcessing,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[isProcessing, progress, errorMessage];
}

class FileOperationController extends StateNotifier<FileOperationState> {
  FileOperationController(this._service)
      : super(const FileOperationState.initial());

  final FileOperationService _service;

  Future<void> deleteFile({
    required SmbConnection connection,
    required String path,
  }) async {
    state = state.copyWith(isProcessing: true, progress: 0, clearError: true);
    try {
      await _service.deleteFile(connection: connection, path: path);
      state = state.copyWith(isProcessing: false, progress: 1);
    } catch (error) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to delete file.',
      );
    }
  }

  Future<void> uploadFile({
    required SmbConnection connection,
    required String targetDirectory,
  }) async {
    state = state.copyWith(isProcessing: true, progress: 0, clearError: true);
    try {
      await _service.uploadFile(
        connection: connection,
        targetDirectory: targetDirectory,
        onProgress: (double progress) =>
            state = state.copyWith(progress: progress),
      );
      state = state.copyWith(isProcessing: false, progress: 1);
    } catch (error) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'File upload failed.',
      );
    }
  }

  Future<void> createFolder({
    required SmbConnection connection,
    required String parentPath,
    required String folderName,
  }) async {
    state = state.copyWith(isProcessing: true, progress: 0, clearError: true);
    try {
      await _service.createFolder(
        connection: connection,
        parentPath: parentPath,
        folderName: folderName,
      );
      state = state.copyWith(isProcessing: false, progress: 1);
    } catch (_) {
      state = state.copyWith(
          isProcessing: false, errorMessage: 'Failed to create folder.');
    }
  }

  Future<void> createFile({
    required SmbConnection connection,
    required String parentPath,
    required String fileName,
  }) async {
    state = state.copyWith(isProcessing: true, progress: 0, clearError: true);
    try {
      await _service.createFile(
        connection: connection,
        parentPath: parentPath,
        fileName: fileName,
      );
      state = state.copyWith(isProcessing: false, progress: 1);
    } catch (_) {
      state = state.copyWith(
          isProcessing: false, errorMessage: 'Failed to create file.');
    }
  }
}

final StateNotifierProvider<FileOperationController, FileOperationState>
    fileOperationControllerProvider =
    StateNotifierProvider<FileOperationController, FileOperationState>(
  (Ref ref) => FileOperationController(getIt<FileOperationService>()),
);
