import 'package:flutter/material.dart';

class PathBreadcrumb extends StatelessWidget {
  const PathBreadcrumb({
    required this.paths,
    required this.currentPath,
    required this.onPathTapped,
    super.key,
  });

  final List<String> paths;
  final String currentPath;
  final ValueChanged<String> onPathTapped;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: paths.map((String path) {
          final bool isCurrent = path == currentPath;
          final String label = path == '/' ? 'Root' : path.split('/').last;

          return Row(
            children: <Widget>[
              TextButton(
                onPressed: isCurrent ? null : () => onPathTapped(path),
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (!isCurrent) const Icon(Icons.chevron_right_rounded, size: 16),
            ],
          );
        }).toList(growable: false),
      ),
    );
  }
}
