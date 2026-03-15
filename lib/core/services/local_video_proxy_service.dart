import 'dart:io';
import 'dart:math';

import 'package:smb_connect/smb_connect.dart';

import 'smb_session_service.dart';

class LocalVideoProxyService {
  LocalVideoProxyService(this._smbSessionService);

  final SmbSessionService _smbSessionService;
  HttpServer? _server;

  Future<String> streamUrl({
    required String connectionId,
    required String smbPath,
  }) async {
    await _ensureStarted();
    final String normalizedPath = smbPath.startsWith('/')
        ? smbPath
        : '/$smbPath';
    final String fileName = normalizedPath.split('/').last;
    final String safeFileName = fileName.isEmpty ? 'stream.mp4' : fileName;

    return Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: _server!.port,
      path: '/video/$safeFileName',
      queryParameters: <String, String>{
        'cid': connectionId,
        'path': normalizedPath,
      },
    ).toString();
  }

  Future<void> _ensureStarted() async {
    if (_server != null) {
      return;
    }

    _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
      shared: true,
    );

    _server!.listen(_handleRequest);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (!request.uri.path.startsWith('/video/')) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not found');
      await request.response.close();
      return;
    }

    final String? connectionId = request.uri.queryParameters['cid'];
    final String? smbPath = request.uri.queryParameters['path'];
    if (connectionId == null || smbPath == null) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('Missing parameters');
      await request.response.close();
      return;
    }

    final SmbConnect? client = _smbSessionService.clientOf(connectionId);
    if (client == null) {
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..write('SMB session is not available');
      await request.response.close();
      return;
    }

    try {
      final SmbFile smbFile = await client.file(smbPath);
      final int fileSize = max(0, smbFile.size);

      final _RangeRequest range = _parseRange(
        rangeHeader: request.headers.value(HttpHeaders.rangeHeader),
        fileSize: fileSize,
      );

      if (range.invalid) {
        request.response
          ..statusCode = HttpStatus.requestedRangeNotSatisfiable
          ..headers.set(HttpHeaders.contentRangeHeader, 'bytes */$fileSize');
        await request.response.close();
        return;
      }

      final int start = range.start;
      final int end = range.end;
      final int contentLength = end - start + 1;

      final Stream<List<int>> stream = await client.openRead(
        smbFile,
        start,
        end + 1,
      );

      final HttpResponse response = request.response;
      response.headers
        ..set(HttpHeaders.acceptRangesHeader, 'bytes')
        ..set(HttpHeaders.contentTypeHeader, _guessMimeType(smbPath))
        ..set(HttpHeaders.contentLengthHeader, contentLength.toString())
        ..set(HttpHeaders.cacheControlHeader, 'no-store')
        ..set(HttpHeaders.connectionHeader, 'keep-alive');

      if (range.isPartial) {
        response
          ..statusCode = HttpStatus.partialContent
          ..headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes $start-$end/$fileSize',
          );
      } else {
        response.statusCode = HttpStatus.ok;
      }

      if (request.method.toUpperCase() == 'HEAD') {
        await response.close();
        return;
      }

      await response.addStream(stream);
      await response.close();
    } catch (_) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Unable to stream SMB file');
      await request.response.close();
    }
  }

  String _guessMimeType(String path) {
    final String lower = path.toLowerCase();
    if (lower.endsWith('.mp4') || lower.endsWith('.m4v')) {
      return 'video/mp4';
    }
    if (lower.endsWith('.mkv')) {
      return 'video/x-matroska';
    }
    if (lower.endsWith('.mov')) {
      return 'video/quicktime';
    }
    if (lower.endsWith('.webm')) {
      return 'video/webm';
    }
    if (lower.endsWith('.avi')) {
      return 'video/x-msvideo';
    }
    return 'application/octet-stream';
  }

  _RangeRequest _parseRange({
    required String? rangeHeader,
    required int fileSize,
  }) {
    if (fileSize <= 0) {
      return const _RangeRequest(
        start: 0,
        end: 0,
        isPartial: false,
        invalid: true,
      );
    }

    if (rangeHeader == null || !rangeHeader.startsWith('bytes=')) {
      return _RangeRequest(
        start: 0,
        end: fileSize - 1,
        isPartial: false,
        invalid: false,
      );
    }

    final String value = rangeHeader.substring(6).trim();
    final List<String> parts = value.split('-');
    if (parts.length != 2) {
      return const _RangeRequest(
        start: 0,
        end: 0,
        isPartial: true,
        invalid: true,
      );
    }

    final String startPart = parts[0].trim();
    final String endPart = parts[1].trim();

    final int? parsedStart = startPart.isEmpty ? null : int.tryParse(startPart);
    final int? parsedEnd = endPart.isEmpty ? null : int.tryParse(endPart);

    int start;
    int end;

    if (parsedStart == null) {
      if (parsedEnd == null) {
        return const _RangeRequest(
          start: 0,
          end: 0,
          isPartial: true,
          invalid: true,
        );
      }
      final int suffixLength = min(parsedEnd, fileSize);
      start = fileSize - suffixLength;
      end = fileSize - 1;
    } else {
      start = parsedStart;
      end = parsedEnd ?? (fileSize - 1);
    }

    if (start < 0 || start >= fileSize || end < start) {
      return const _RangeRequest(
        start: 0,
        end: 0,
        isPartial: true,
        invalid: true,
      );
    }

    if (end >= fileSize) {
      end = fileSize - 1;
    }

    return _RangeRequest(
      start: start,
      end: end,
      isPartial: true,
      invalid: false,
    );
  }
}

class _RangeRequest {
  const _RangeRequest({
    required this.start,
    required this.end,
    required this.isPartial,
    required this.invalid,
  });

  final int start;
  final int end;
  final bool isPartial;
  final bool invalid;
}
