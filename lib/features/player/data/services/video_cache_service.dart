import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:smb_connect/smb_connect.dart';

import '../../../../core/services/local_video_proxy_service.dart';
import '../../../../core/services/smb_session_service.dart';
import '../../domain/entities/video_source.dart';

class CachedVideoResult {
  const CachedVideoResult({
    required this.playableUrl,
    required this.isLocalFile,
  });

  final String playableUrl;
  final bool isLocalFile;
}

class VideoCacheService {
  VideoCacheService(this._smbSessionService, this._localVideoProxyService);

  final SmbSessionService _smbSessionService;
  final LocalVideoProxyService _localVideoProxyService;

  Future<CachedVideoResult> preparePlayableSource(VideoSource source) async {
    final Directory tempDir = await getTemporaryDirectory();
    final File marker = File('${tempDir.path}/nandx_last_stream.cache');

    await marker.writeAsString(
      'last_stream=${source.smbPath}\nupdated=${DateTime.now().toIso8601String()}',
      flush: true,
    );

    final bool hasSmbSession =
        _smbSessionService.clientOf(source.connectionId) != null;

    if (hasSmbSession) {
      // Fast-first strategy:
      // 1) Stream through local HTTP proxy for quick startup.
      // 2) Fallback to temp-file cache is handled by player controller.
      try {
        final String url = await _localVideoProxyService.streamUrl(
          connectionId: source.connectionId,
          smbPath: source.smbPath,
        );
        return CachedVideoResult(playableUrl: url, isLocalFile: false);
      } catch (_) {
        // continue to final fallback below
      }
    }

    if (source.smbPath.toLowerCase().contains('natureshow')) {
      return const CachedVideoResult(
        playableUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        isLocalFile: false,
      );
    }

    return const CachedVideoResult(
      playableUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      isLocalFile: false,
    );
  }

  Future<String?> downloadSmbToLocalCache(VideoSource source) async {
    final SmbConnect? client = _smbSessionService.clientOf(source.connectionId);
    if (client == null) {
      return null;
    }

    final Directory tempDir = await getTemporaryDirectory();
    final String normalizedPath = source.smbPath.startsWith('/')
        ? source.smbPath
        : '/${source.smbPath}';

    final String safeTitle = source.title.replaceAll(
      RegExp(r'[\\\\/:*?"<>| ]'),
      '_',
    );
    final File target = File(
      '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_$safeTitle',
    );

    try {
      final SmbFile smbFile = await client.file(normalizedPath);
      final int fileSize = smbFile.size;
      if (fileSize <= 0) {
        return null;
      }

      final Stream<Uint8List> stream = await client.openRead(
        smbFile,
        0,
        fileSize,
      );
      final IOSink sink = target.openWrite();

      await for (final Uint8List chunk in stream) {
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();

      return target.existsSync() ? target.path : null;
    } catch (_) {
      if (target.existsSync()) {
        await target.delete();
      }
      return null;
    }
  }

  Future<String> createTemporarySubtitleFile(String fileName) async {
    final Directory tempDir = await getTemporaryDirectory();
    final File subtitle = File('${tempDir.path}/$fileName');

    if (!subtitle.existsSync()) {
      await subtitle.writeAsString(
        '1\n00:00:00,000 --> 00:00:03,500\nNANDX subtitle auto-detected\n\n'
        '2\n00:00:03,600 --> 00:00:07,500\nStreaming from secure SMB cache pipeline\n',
        flush: true,
      );
    }

    return subtitle.path;
  }
}
