import 'package:collection/collection.dart';

import '../entities/file_item.dart';
import '../entities/sort_mode.dart';

class FileSortingService {
  const FileSortingService();

  List<FileItem> sort(List<FileItem> items, SortMode sortMode) {
    switch (sortMode) {
      case SortMode.name:
        return items.sortedBy((FileItem item) => item.name.toLowerCase());
      case SortMode.createdAt:
        return items.sorted(
            (FileItem a, FileItem b) => b.createdAt.compareTo(a.createdAt));
      case SortMode.dynamic:
        final List<FileItem> copied = List<FileItem>.from(items);
        copied.sort((FileItem a, FileItem b) {
          if (a.isFolder != b.isFolder) {
            return a.isFolder ? -1 : 1;
          }

          final int recency = b.modifiedAt.compareTo(a.modifiedAt);
          if (recency != 0) {
            return recency;
          }

          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        return copied;
    }
  }
}
