class FileUtils {
  const FileUtils._();

  static const List<String> _videoExtensions = <String>[
    '.mp4',
    '.mkv',
    '.mov',
    '.avi',
    '.m4v',
    '.webm',
  ];

  static const List<String> _subtitleExtensions = <String>[
    '.srt',
    '.vtt',
    '.ass',
    '.ssa',
  ];

  static bool isVideo(String fileName) {
    final String lower = fileName.toLowerCase();
    return _videoExtensions.any(lower.endsWith);
  }

  static bool isSubtitle(String fileName) {
    final String lower = fileName.toLowerCase();
    return _subtitleExtensions.any(lower.endsWith);
  }

  static String fileName(String path) {
    final List<String> segments = path.split('/');
    return segments.isEmpty ? path : segments.last;
  }

  static String baseNameWithoutExtension(String fileName) {
    final int dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0) {
      return fileName;
    }
    return fileName.substring(0, dotIndex);
  }

  static String humanReadableBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
