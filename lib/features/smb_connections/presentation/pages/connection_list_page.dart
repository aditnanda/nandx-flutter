import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/smb_connection.dart';
import '../controllers/smb_controller.dart';
import '../widgets/connection_tile.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';

class ConnectionListPage extends ConsumerWidget {
  const ConnectionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SmbState state = ref.watch(smbControllerProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/branding/nandx_icon.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.shield_rounded, size: 24),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(AppConstants.appName),
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).lock(),
            icon: const Icon(Icons.lock_outline_rounded),
            tooltip: 'Lock app',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.addConnection),
        icon: const Icon(Icons.add),
        label: const Text('Add SMB'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(smbControllerProvider.notifier).loadConnections(),
        child: _Body(state: state),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final SmbState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.connections.isEmpty) {
      return const LoadingView(message: 'Loading SMB connections...');
    }

    if (state.errorMessage != null && state.connections.isEmpty) {
      return ErrorView(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(smbControllerProvider.notifier).loadConnections(),
      );
    }

    if (state.connections.isEmpty) {
      return const EmptyView(
        message: 'No SMB connections yet. Add one to start browsing.',
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: state.connections.length,
      itemBuilder: (BuildContext context, int index) {
        final SmbConnection connection = state.connections[index];

        return Dismissible(
          key: ValueKey<String>(connection.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          confirmDismiss: (_) async {
            return (await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('Delete connection?'),
                    content: Text(
                        'Remove ${connection.name} from saved SMB servers.'),
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
                )) ??
                false;
          },
          onDismissed: (_) => ref
              .read(smbControllerProvider.notifier)
              .deleteConnection(connection.id),
          child: ConnectionTile(
            connection: connection,
            isConnecting: state.connectingId == connection.id,
            onTap: () async {
              final bool connected = await ref
                  .read(smbControllerProvider.notifier)
                  .connect(connection);
              if (!context.mounted || !connected) {
                return;
              }
              Navigator.of(context).pushNamed(
                AppRoutes.fileBrowser,
                arguments: FileBrowserRouteArgs(connection),
              );
            },
            onEdit: () {
              Navigator.of(context).pushNamed(
                AppRoutes.addConnection,
                arguments: AddConnectionRouteArgs(connection),
              );
            },
            onDelete: () {
              ref
                  .read(smbControllerProvider.notifier)
                  .deleteConnection(connection.id);
            },
          ),
        );
      },
    );
  }
}
