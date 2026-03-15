import 'package:flutter/material.dart';

import '../features/file_browser/domain/entities/file_item.dart';
import '../features/file_browser/presentation/pages/file_browser_page.dart';
import '../features/player/domain/entities/video_source.dart';
import '../features/player/presentation/pages/video_player_page.dart';
import '../features/smb_connections/domain/entities/smb_connection.dart';
import '../features/smb_connections/presentation/pages/add_connection_page.dart';
import '../features/smb_connections/presentation/pages/connection_list_page.dart';

class AppRoutes {
  const AppRoutes._();

  static const String connections = '/connections';
  static const String addConnection = '/connections/add';
  static const String fileBrowser = '/browser';
  static const String videoPlayer = '/player';
}

class AddConnectionRouteArgs {
  const AddConnectionRouteArgs(this.initialConnection);

  final SmbConnection? initialConnection;
}

class FileBrowserRouteArgs {
  const FileBrowserRouteArgs(this.connection);

  final SmbConnection connection;
}

class PlayerRouteArgs {
  const PlayerRouteArgs({required this.source, required this.siblingItems});

  final VideoSource source;
  final List<FileItem> siblingItems;
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.connections:
        return MaterialPageRoute<void>(
          builder: (_) => const ConnectionListPage(),
          settings: settings,
        );
      case AppRoutes.addConnection:
        final AddConnectionRouteArgs? args =
            settings.arguments as AddConnectionRouteArgs?;
        return MaterialPageRoute<void>(
          builder: (_) =>
              AddConnectionPage(initialConnection: args?.initialConnection),
          settings: settings,
        );
      case AppRoutes.fileBrowser:
        final FileBrowserRouteArgs? args =
            settings.arguments as FileBrowserRouteArgs?;
        if (args == null) {
          return _errorRoute('File browser route requires a connection.');
        }
        return MaterialPageRoute<void>(
          builder: (_) => FileBrowserPage(connection: args.connection),
          settings: settings,
        );
      case AppRoutes.videoPlayer:
        final PlayerRouteArgs? args = settings.arguments as PlayerRouteArgs?;
        if (args == null) {
          return _errorRoute('Video player route requires source arguments.');
        }
        return MaterialPageRoute<void>(
          builder: (_) => VideoPlayerPage(
            source: args.source,
            siblingItems: args.siblingItems,
          ),
          settings: settings,
        );
      default:
        return _errorRoute('Unknown route: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Route Error')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
