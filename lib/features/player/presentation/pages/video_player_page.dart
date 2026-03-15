import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

import '../../../file_browser/domain/entities/file_item.dart';
import '../../domain/entities/video_source.dart';
import '../controllers/player_controller.dart';

class VideoPlayerPage extends ConsumerStatefulWidget {
  const VideoPlayerPage({
    required this.source,
    required this.siblingItems,
    super.key,
  });

  final VideoSource source;
  final List<FileItem> siblingItems;

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  bool _showOverlay = false;
  Timer? _ticker;
  Timer? _overlayAutoHideTimer;

  PlayerInitArgs get _args => PlayerInitArgs(
        source: widget.source,
        siblingNames: widget.siblingItems
            .map((FileItem e) => e.name)
            .toList(growable: false),
      );

  @override
  void initState() {
    super.initState();
    _enterLandscapeFullscreen();

    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _overlayAutoHideTimer?.cancel();
    _exitFullscreenMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlayerState state = ref.watch(playerControllerProvider(_args));
    final PlayerController notifier = ref.read(
      playerControllerProvider(_args).notifier,
    );

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Preparing video stream...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    if (state.errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    final VlcPlayerController? vlcController = state.vlcPlayerController;
    final Duration duration = state.duration;
    final Duration position = state.position;

    final int durationMs = duration.inMilliseconds;
    final int positionMs = position.inMilliseconds;
    final double sliderMax = durationMs > 0 ? durationMs.toDouble() : 1;
    final double sliderValue =
        positionMs.clamp(0, sliderMax.toInt()).toDouble();

    final double aspectRatio =
        ((vlcController?.value.aspectRatio ?? (16 / 9)).clamp(0.5, 3.0))
            .toDouble();

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _toggleOverlay,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: vlcController == null
                  ? const SizedBox.shrink()
                  : Center(
                      child: VlcPlayer(
                        controller: vlcController,
                        aspectRatio: aspectRatio,
                        virtualDisplay: false,
                        placeholder: const SizedBox.shrink(),
                      ),
                    ),
            ),
            if (!_showOverlay)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showControls,
                  child: const SizedBox.shrink(),
                ),
              ),
            if (_showOverlay)
              Positioned.fill(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _hideControls,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        children: <Widget>[
                          _TopBar(
                            title: widget.source.title,
                            onBack: () => Navigator.of(context).maybePop(),
                            onCloseOverlay: _hideControls,
                          ),
                          const SizedBox(height: 8),
                          _SideButtons(
                            speed: state.speed,
                            onSpeedDown: () async {
                              await _stepSpeed(
                                state: state,
                                notifier: notifier,
                                increase: false,
                              );
                              _scheduleOverlayAutoHide();
                            },
                            onSpeedUp: () async {
                              await _stepSpeed(
                                state: state,
                                notifier: notifier,
                                increase: true,
                              );
                              _scheduleOverlayAutoHide();
                            },
                            onSubtitle: () => _openSubtitleSheet(
                              state,
                              notifier,
                            ),
                          ),
                          const Spacer(),
                          _ProgressRow(
                            position: position,
                            duration: duration,
                            sliderMax: sliderMax,
                            sliderValue: sliderValue,
                            onSeek: (double value) {
                              notifier.seekTo(
                                Duration(milliseconds: value.toInt()),
                              );
                              _scheduleOverlayAutoHide();
                            },
                          ),
                          const SizedBox(height: 8),
                          _PlaybackRow(
                            isPlaying: state.isPlaying,
                            onPlayPause: () async {
                              await notifier.togglePlayPause();
                              _scheduleOverlayAutoHide();
                            },
                            onSeekBackward: () async {
                              await notifier.seekBy(
                                const Duration(seconds: -30),
                              );
                              _scheduleOverlayAutoHide();
                            },
                            onSeekForward: () async {
                              await notifier.seekBy(
                                const Duration(seconds: 30),
                              );
                              _scheduleOverlayAutoHide();
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleOverlay() {
    if (_showOverlay) {
      _hideControls();
      return;
    }
    _showControls();
  }

  void _showControls() {
    _overlayAutoHideTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() => _showOverlay = true);
    _scheduleOverlayAutoHide();
  }

  void _hideControls() {
    _overlayAutoHideTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() => _showOverlay = false);
  }

  void _scheduleOverlayAutoHide() {
    _overlayAutoHideTimer?.cancel();
    _overlayAutoHideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) {
        return;
      }
      setState(() => _showOverlay = false);
    });
  }

  Future<void> _openSubtitleSheet(
    PlayerState state,
    PlayerController notifier,
  ) {
    _overlayAutoHideTimer?.cancel();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151515),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ListTile(
                title: Text('Subtitles', style: TextStyle(color: Colors.white)),
              ),
              ...state.subtitles.entries.map(
                (MapEntry<String, String> item) => ListTile(
                  title: Text(
                    item.key,
                    style: TextStyle(
                      color: state.selectedSubtitlePath == item.value
                          ? Colors.white
                          : Colors.white70,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await notifier.selectSubtitle(
                      path: item.value,
                      label: item.key,
                    );
                  },
                ),
              ),
              ListTile(
                title: const Text(
                  'Select external subtitle',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await notifier.pickExternalSubtitle();
                },
              ),
            ],
          ),
        );
      },
    ).whenComplete(_scheduleOverlayAutoHide);
  }

  Future<void> _enterLandscapeFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _exitFullscreenMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _stepSpeed({
    required PlayerState state,
    required PlayerController notifier,
    required bool increase,
  }) async {
    final List<double> speeds = state.availableSpeeds;
    final int currentIndex = speeds.indexOf(state.speed);
    if (currentIndex == -1) {
      return;
    }

    final int nextIndex = increase
        ? (currentIndex + 1).clamp(0, speeds.length - 1)
        : (currentIndex - 1).clamp(0, speeds.length - 1);

    await notifier.setSpeed(speeds[nextIndex]);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onCloseOverlay,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onCloseOverlay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: <Widget>[
          _CircleIconButton(
            icon: Icons.arrow_back,
            onTap: onBack,
            size: 36,
            iconSize: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _CircleIconButton(
            icon: Icons.close,
            onTap: onCloseOverlay,
            size: 36,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

class _SideButtons extends StatelessWidget {
  const _SideButtons({
    required this.speed,
    required this.onSpeedDown,
    required this.onSpeedUp,
    required this.onSubtitle,
  });

  final double speed;
  final VoidCallback onSpeedDown;
  final VoidCallback onSpeedUp;
  final VoidCallback onSubtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          _CircleIconButton(
            icon: Icons.remove,
            onTap: onSpeedDown,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 10),
          Text(
            '${speed.toStringAsFixed(2)}x',
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(width: 10),
          _CircleIconButton(
            icon: Icons.add,
            onTap: onSpeedUp,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 10),
          _CircleIconButton(
            icon: Icons.subtitles_outlined,
            onTap: onSubtitle,
            size: 40,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.position,
    required this.duration,
    required this.sliderMax,
    required this.sliderValue,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final double sliderMax;
  final double sliderValue;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Text(
            _formatDuration(position),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF8D7DFF),
                inactiveTrackColor: const Color(0x80A7A7D8),
                thumbColor: Colors.white,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                min: 0,
                max: sliderMax,
                value: sliderValue,
                onChanged: onSeek,
              ),
            ),
          ),
          Text(
            _formatDuration(duration),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final int minutes = d.inMinutes.remainder(60);
    final int seconds = d.inSeconds.remainder(60);
    final int hours = d.inHours;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _PlaybackRow extends StatelessWidget {
  const _PlaybackRow({
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSeekBackward,
    required this.onSeekForward,
  });

  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekBackward;
  final VoidCallback onSeekForward;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _SeekButton(
            onTap: onSeekBackward,
            label: '30',
            icon: Icons.replay_30_rounded,
          ),
          const SizedBox(width: 10),
          _CircleIconButton(
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onTap: onPlayPause,
            size: 62,
            iconSize: 34,
          ),
          const SizedBox(width: 10),
          _SeekButton(
            onTap: onSeekForward,
            label: '30',
            icon: Icons.forward_30_rounded,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.size = 52,
    this.iconSize = 30,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0x22000000),
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(color: const Color(0x77FFFFFF)),
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}

class _SeekButton extends StatelessWidget {
  const _SeekButton({
    required this.onTap,
    required this.label,
    required this.icon,
  });

  final VoidCallback onTap;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 24),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
