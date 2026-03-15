import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../file_operations/presentation/controllers/file_operation_controller.dart';
import '../../../file_operations/presentation/widgets/file_action_menu.dart';
import '../../../player/domain/entities/video_source.dart';
import '../../../smb_connections/domain/entities/smb_connection.dart';
import '../../domain/entities/file_item.dart';
import '../../presentation/controllers/file_browser_controller.dart';
import '../widgets/file_tile.dart';
import '../widgets/path_breadcrumb.dart';
import '../widgets/sort_menu.dart';

class FileBrowserPage extends ConsumerWidget {
  const FileBrowserPage({required this.connection, super.key});

  final SmbConnection connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FileBrowserState state =
        ref.watch(fileBrowserControllerProvider(connection));
    final FileOperationState operationState =
        ref.watch(fileOperationControllerProvider);

    ref.listen<FileOperationState>(fileOperationControllerProvider,
        (FileOperationState? _, FileOperationState next) {
      if (next.errorMessage != null && context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }

      if (!next.isProcessing && next.progress == 1 && context.mounted) {
        ref.read(fileBrowserControllerProvider(connection).notifier).refresh();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(connection.name),
        actions: <Widget>[
          SortMenu(
            currentMode: state.sortMode,
            onChanged: (sortMode) => ref
                .read(fileBrowserControllerProvider(connection).notifier)
                .setSortMode(sortMode),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: PathBreadcrumb(
                paths: state.breadcrumbs,
                currentPath: state.currentPath,
                onPathTapped: (String path) => ref
                    .read(fileBrowserControllerProvider(connection).notifier)
                    .navigateToBreadcrumb(path),
              ),
            ),
          ),
          if (operationState.isProcessing)
            LinearProgressIndicator(value: operationState.progress),
          Expanded(child: _buildBody(context, ref, state)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFolderActions(
          context,
          ref,
          null,
          connection,
          state.currentPath,
        ),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('Actions'),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, FileBrowserState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingView(message: 'Loading files...');
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return ErrorView(
        message: state.errorMessage!,
        onRetry: () => ref
            .read(fileBrowserControllerProvider(connection).notifier)
            .refresh(),
      );
    }

    if (state.items.isEmpty) {
      return const EmptyView(message: 'Folder is empty.');
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(fileBrowserControllerProvider(connection).notifier)
          .refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        itemCount: state.items.length,
        itemBuilder: (BuildContext context, int index) {
          final FileItem item = state.items[index];
          return FileTile(
            item: item,
            onTap: () {
              if (item.isFolder) {
                ref
                    .read(fileBrowserControllerProvider(connection).notifier)
                    .navigateToFolder(item);
                return;
              }

              if (FileUtils.isVideo(item.name)) {
                Navigator.of(context).pushNamed(
                  AppRoutes.videoPlayer,
                  arguments: PlayerRouteArgs(
                    source: VideoSource(
                      smbPath: item.path,
                      title: item.name,
                      connectionId: connection.id,
                    ),
                    siblingItems: state.items,
                  ),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Preview for ${item.name} is not implemented.')),
              );
            },
            onLongPress: () => _showFolderActions(
              context,
              ref,
              item,
              connection,
              state.currentPath,
            ),
          );
        },
      ),
    );
  }

  Future<void> _showFolderActions(
    BuildContext context,
    WidgetRef ref,
    FileItem? selectedItem,
    SmbConnection connection,
    String currentPath,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return FileActionMenu(
          onDelete: () async {
            Navigator.of(bottomSheetContext).pop();
            if (selectedItem == null) {
              return;
            }

            final bool? confirm = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Delete File?'),
                content: Text('Delete ${selectedItem.name} permanently?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );

            if (confirm != true || !context.mounted) {
              return;
            }

            await ref.read(fileOperationControllerProvider.notifier).deleteFile(
                  connection: connection,
                  path: selectedItem.path,
                );
          },
          onUpload: () async {
            Navigator.of(bottomSheetContext).pop();
            await ref.read(fileOperationControllerProvider.notifier).uploadFile(
                  connection: connection,
                  targetDirectory: currentPath,
                );
          },
          onCreateFolder: () async {
            Navigator.of(bottomSheetContext).pop();
            final String? folderName = await _showNameInputDialog(
              context: context,
              title: 'Create Folder',
              hintText: 'Folder name',
            );
            if (folderName == null || !context.mounted) {
              return;
            }
            await ref
                .read(fileOperationControllerProvider.notifier)
                .createFolder(
                  connection: connection,
                  parentPath: currentPath,
                  folderName: folderName,
                );
          },
          onCreateFile: () async {
            Navigator.of(bottomSheetContext).pop();
            final String? fileName = await _showNameInputDialog(
              context: context,
              title: 'Create New File',
              hintText: 'Filename.ext',
            );
            if (fileName == null || !context.mounted) {
              return;
            }
            await ref.read(fileOperationControllerProvider.notifier).createFile(
                  connection: connection,
                  parentPath: currentPath,
                  fileName: fileName,
                );
          },
        );
      },
    );
  }

  Future<String?> _showNameInputDialog({
    required BuildContext context,
    required String title,
    required String hintText,
  }) {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final String value = controller.text.trim();
                if (value.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(value);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
