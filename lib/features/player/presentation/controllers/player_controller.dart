import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/file_utils.dart';
import '../../data/services/video_cache_service.dart';
import '../../domain/entities/video_source.dart';

class PlayerInitArgs extends Equatable {
  const PlayerInitArgs({required this.source, required this.siblingNames});

  final VideoSource source;
  final List<String> siblingNames;

  @override
  List<Object?> get props => <Object?>[source, siblingNames.join('|')];
}

class PlayerState extends Equatable {
  const PlayerState({
    required this.isLoading,
    required this.speed,
    required this.availableSpeeds,
    required this.isPlaying,
    required this.isBuffering,
    required this.position,
    required this.duration,
    this.errorMessage,
    this.vlcPlayerController,
    this.subtitles = const <String, String>{},
    this.selectedSubtitlePath,
  });

  const PlayerState.initial()
      : isLoading = true,
        speed = 1,
        availableSpeeds = const <double>[0.5, 1, 1.25, 1.5, 2],
        isPlaying = false,
        isBuffering = false,
        position = Duration.zero,
        duration = Duration.zero,
        errorMessage = null,
        vlcPlayerController = null,
        subtitles = const <String, String>{},
        selectedSubtitlePath = null;

  final bool isLoading;
  final String? errorMessage;
  final double speed;
  final List<double> availableSpeeds;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final VlcPlayerController? vlcPlayerController;
  final Map<String, String> subtitles;
  final String? selectedSubtitlePath;

  PlayerState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    double? speed,
    List<double>? availableSpeeds,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    VlcPlayerController? vlcPlayerController,
    Map<String, String>? subtitles,
    String? selectedSubtitlePath,
  }) {
    return PlayerState(
      isLoading: isLoading ?? this.isLoading,
      speed: speed ?? this.speed,
      availableSpeeds: availableSpeeds ?? this.availableSpeeds,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      vlcPlayerController: vlcPlayerController ?? this.vlcPlayerController,
      subtitles: subtitles ?? this.subtitles,
      selectedSubtitlePath: selectedSubtitlePath ?? this.selectedSubtitlePath,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        isLoading,
        errorMessage,
        speed,
        availableSpeeds,
        isPlaying,
        isBuffering,
        position,
        duration,
        vlcPlayerController,
        subtitles,
        selectedSubtitlePath,
      ];
}

class PlayerController extends StateNotifier<PlayerState> {
  PlayerController(this._args, this._videoCacheService)
      : super(const PlayerState.initial()) {
    _initialize();
  }

  final PlayerInitArgs _args;
  final VideoCacheService _videoCacheService;

  VlcPlayerController? _vlcPlayerController;
  VlcPlayerController? _listenerOwnerController;
  VoidCallback? _vlcValueListener;
  bool _localFallbackAttempted = false;

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final CachedVideoResult stream = await _videoCacheService
          .preparePlayableSource(_args.source)
          .timeout(const Duration(seconds: 20));

      final Map<String, String> subtitles = await _detectSubtitles(
        _args.siblingNames,
      );
      final String? defaultSubtitlePath = subtitles.values.firstOrNull;

      _localFallbackAttempted = stream.isLocalFile;
      _vlcPlayerController = _createController(
        playableUrl: stream.playableUrl,
        isLocalFile: stream.isLocalFile,
      );

      _attachVlcListener(_vlcPlayerController!);

      state = state.copyWith(
        isLoading: false,
        vlcPlayerController: _vlcPlayerController,
        subtitles: subtitles,
        selectedSubtitlePath: defaultSubtitlePath,
        isPlaying: false,
        isBuffering: true,
      );

      if (defaultSubtitlePath != null) {
        unawaited(_waitForInitAndApplySubtitle(defaultSubtitlePath));
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize video player: $error',
      );
    }
  }

  VlcPlayerController _createController({
    required String playableUrl,
    required bool isLocalFile,
  }) {
    final VlcPlayerOptions options = VlcPlayerOptions(
      advanced: VlcAdvancedOptions(<String>[
        VlcAdvancedOptions.fileCaching(1500),
        VlcAdvancedOptions.networkCaching(2200),
        VlcAdvancedOptions.liveCaching(1800),
        VlcAdvancedOptions.clockSynchronization(0),
      ]),
      http: VlcHttpOptions(<String>[
        VlcHttpOptions.httpReconnect(true),
        VlcHttpOptions.httpContinuous(true),
        VlcHttpOptions.httpForwardCookies(true),
        VlcHttpOptions.httpUserAgent('NANDX/1.0'),
      ]),
      extras: const <String>[
        '--drop-late-frames',
        '--skip-frames',
      ],
    );

    if (isLocalFile) {
      return VlcPlayerController.file(
        File(playableUrl),
        autoPlay: true,
        hwAcc: HwAcc.full,
        options: options,
      );
    }

    return VlcPlayerController.network(
      playableUrl,
      autoPlay: true,
      hwAcc: HwAcc.full,
      options: options,
    );
  }

  void _attachVlcListener(VlcPlayerController controller) {
    if (_listenerOwnerController != null && _vlcValueListener != null) {
      _listenerOwnerController!.removeListener(_vlcValueListener!);
    }

    _vlcValueListener = () {
      final VlcPlayerValue value = controller.value;
      final String? playerError =
          value.hasError ? value.errorDescription : null;

      final bool changed = state.isPlaying != value.isPlaying ||
          state.isBuffering != value.isBuffering ||
          state.position != value.position ||
          state.duration != value.duration ||
          state.errorMessage != playerError;

      if (changed) {
        state = state.copyWith(
          isPlaying: value.isPlaying,
          isBuffering: value.isBuffering,
          position: value.position,
          duration: value.duration,
          errorMessage: playerError,
          clearError: !value.hasError,
        );
      }

      if (value.hasError) {
        unawaited(_tryLocalFallback());
      }
    };

    controller.addListener(_vlcValueListener!);
    _listenerOwnerController = controller;
  }

  Future<void> togglePlayPause() async {
    final VlcPlayerController? controller = state.vlcPlayerController;
    if (controller == null) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
      return;
    }

    await controller.play();
    await controller.setPlaybackSpeed(state.speed);
  }

  Future<void> seekBy(Duration offset) async {
    final VlcPlayerController? controller = state.vlcPlayerController;
    if (controller == null) {
      return;
    }

    final Duration target = controller.value.position + offset;
    await controller.seekTo(target);
  }

  Future<void> seekTo(Duration position) async {
    final VlcPlayerController? controller = state.vlcPlayerController;
    if (controller == null) {
      return;
    }
    await controller.seekTo(position);
  }

  Future<void> setSpeed(double speed) async {
    final VlcPlayerController? controller = state.vlcPlayerController;
    if (controller == null) {
      return;
    }

    if (!controller.value.isPlaying) {
      await controller.play();
    }
    await controller.setPlaybackSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  Future<void> pickExternalSubtitle() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: const <String>['srt', 'vtt', 'ass', 'ssa'],
      type: FileType.custom,
    );

    final String? path = result?.files.single.path;
    if (path == null) {
      return;
    }

    final String label = result!.files.single.name;
    final Map<String, String> updated = Map<String, String>.from(
      state.subtitles,
    )..[label] = path;

    await selectSubtitle(path: path, label: label, allSubtitles: updated);
  }

  Future<void> selectSubtitle({
    required String path,
    required String label,
    Map<String, String>? allSubtitles,
  }) async {
    await _waitForInitAndApplySubtitle(path);
    state = state.copyWith(
      subtitles: allSubtitles ?? state.subtitles,
      selectedSubtitlePath: path,
    );
  }

  Future<void> _waitForInitAndApplySubtitle(String subtitlePath) async {
    final VlcPlayerController? controller = state.vlcPlayerController;
    if (controller == null) {
      return;
    }

    await _waitUntilInitialized(controller,
        timeout: const Duration(seconds: 20));
    await controller.addSubtitleFromFile(File(subtitlePath), isSelected: true);
  }

  Future<void> _waitUntilInitialized(
    VlcPlayerController controller, {
    required Duration timeout,
  }) async {
    if (controller.value.isInitialized) {
      return;
    }

    final Completer<void> completer = Completer<void>();
    late VoidCallback listener;
    listener = () {
      if (controller.value.isInitialized && !completer.isCompleted) {
        completer.complete();
      }
    };

    controller.addListener(listener);
    Timer? timer;

    try {
      timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.completeError(
            TimeoutException('VLC initialization timed out'),
          );
        }
      });
      await completer.future;
    } finally {
      timer?.cancel();
      controller.removeListener(listener);
    }
  }

  Future<void> _tryLocalFallback() async {
    if (_localFallbackAttempted) {
      return;
    }

    _localFallbackAttempted = true;
    final String? localPath = await _videoCacheService
        .downloadSmbToLocalCache(_args.source)
        .timeout(const Duration(seconds: 90));
    if (localPath == null) {
      return;
    }

    final VlcPlayerController? previous = _vlcPlayerController;
    final VlcPlayerController localController = _createController(
      playableUrl: localPath,
      isLocalFile: true,
    );
    _vlcPlayerController = localController;
    _attachVlcListener(localController);

    state = state.copyWith(
      vlcPlayerController: localController,
      clearError: true,
      isBuffering: true,
    );

    await previous?.dispose();
    final String? subtitlePath = state.selectedSubtitlePath;
    if (subtitlePath != null) {
      unawaited(_waitForInitAndApplySubtitle(subtitlePath));
    }
    try {
      await _waitUntilInitialized(
        localController,
        timeout: const Duration(seconds: 20),
      );
      await setSpeed(state.speed);
    } catch (_) {
      // Keep default playback speed if fallback media is still initializing.
    }
  }

  Future<Map<String, String>> _detectSubtitles(
    List<String> siblingNames,
  ) async {
    final String baseName = FileUtils.baseNameWithoutExtension(
      _args.source.title,
    ).toLowerCase();
    final Map<String, String> subtitles = <String, String>{};

    for (final String sibling in siblingNames) {
      if (!FileUtils.isSubtitle(sibling)) {
        continue;
      }
      final String siblingBase = FileUtils.baseNameWithoutExtension(
        sibling,
      ).toLowerCase();
      if (siblingBase != baseName) {
        continue;
      }
      subtitles[sibling] = await _videoCacheService.createTemporarySubtitleFile(
        sibling,
      );
    }

    return subtitles;
  }

  @override
  void dispose() {
    final VlcPlayerController? controller = _listenerOwnerController;
    final VoidCallback? listener = _vlcValueListener;
    if (controller != null && listener != null) {
      controller.removeListener(listener);
    }
    _vlcPlayerController?.dispose();
    super.dispose();
  }
}

final AutoDisposeStateNotifierProviderFamily<PlayerController, PlayerState,
        PlayerInitArgs> playerControllerProvider =
    StateNotifierProvider.autoDispose
        .family<PlayerController, PlayerState, PlayerInitArgs>(
  (Ref ref, PlayerInitArgs args) =>
      PlayerController(args, getIt<VideoCacheService>()),
);

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
