import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../smb_connections/domain/entities/smb_connection.dart';
import '../../domain/entities/file_item.dart';
import '../../domain/entities/sort_mode.dart';
import '../../domain/repositories/file_repository.dart';
import '../../domain/services/file_sorting_service.dart';

class FileBrowserState extends Equatable {
  const FileBrowserState({
    required this.isLoading,
    required this.currentPath,
    required this.items,
    required this.sortMode,
    this.errorMessage,
  });

  const FileBrowserState.initial({required String initialPath})
    : isLoading = true,
      currentPath = initialPath,
      items = const <FileItem>[],
      sortMode = SortMode.dynamic,
      errorMessage = null;

  final bool isLoading;
  final String currentPath;
  final List<FileItem> items;
  final SortMode sortMode;
  final String? errorMessage;

  List<String> get breadcrumbs {
    if (currentPath == '/' || currentPath.isEmpty) {
      return <String>['/'];
    }

    final List<String> segments = currentPath
        .split('/')
        .where((String element) => element.isNotEmpty)
        .toList(growable: false);

    final List<String> paths = <String>['/'];
    String cursor = '';
    for (final String segment in segments) {
      cursor += '/$segment';
      paths.add(cursor);
    }
    return paths;
  }

  FileBrowserState copyWith({
    bool? isLoading,
    String? currentPath,
    List<FileItem>? items,
    SortMode? sortMode,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FileBrowserState(
      isLoading: isLoading ?? this.isLoading,
      currentPath: currentPath ?? this.currentPath,
      items: items ?? this.items,
      sortMode: sortMode ?? this.sortMode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isLoading,
    currentPath,
    items,
    sortMode,
    errorMessage,
  ];
}

class FileBrowserController extends StateNotifier<FileBrowserState> {
  FileBrowserController(
    this._connection,
    this._repository,
    this._sortingService,
  ) : super(
        FileBrowserState.initial(
          initialPath: _normalizePath(_connection.sharedPath),
        ),
      ) {
    loadPath(_normalizePath(_connection.sharedPath));
  }

  final SmbConnection _connection;
  final FileRepository _repository;
  final FileSortingService _sortingService;

  Future<void> loadPath(String path) async {
    state = state.copyWith(
      isLoading: true,
      currentPath: _normalizePath(path),
      clearError: true,
    );

    try {
      final List<FileItem> files = await _repository.listFiles(
        connection: _connection,
        path: state.currentPath,
      );

      state = state.copyWith(
        isLoading: false,
        items: _sortingService.sort(files, state.sortMode),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load folder content.',
      );
    }
  }

  Future<void> refresh() => loadPath(state.currentPath);

  Future<void> navigateToFolder(FileItem folder) => loadPath(folder.path);

  Future<void> navigateToBreadcrumb(String path) => loadPath(path);

  void setSortMode(SortMode sortMode) {
    state = state.copyWith(
      sortMode: sortMode,
      items: _sortingService.sort(state.items, sortMode),
    );
  }

  static String _normalizePath(String rawPath) {
    if (rawPath.isEmpty) {
      return '/';
    }

    String normalized = rawPath;
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }

    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }
}

final AutoDisposeStateNotifierProviderFamily<
  FileBrowserController,
  FileBrowserState,
  SmbConnection
>
fileBrowserControllerProvider = StateNotifierProvider.autoDispose
    .family<FileBrowserController, FileBrowserState, SmbConnection>(
      (Ref ref, SmbConnection connection) => FileBrowserController(
        connection,
        getIt<FileRepository>(),
        getIt<FileSortingService>(),
      ),
    );
