import 'package:flutter/material.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    required this.isPlaying,
    required this.currentSpeed,
    required this.availableSpeeds,
    required this.onPlayPause,
    required this.onSeekBackward,
    required this.onSeekForward,
    required this.onSpeedChanged,
    super.key,
  });

  final bool isPlaying;
  final double currentSpeed;
  final List<double> availableSpeeds;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekBackward;
  final VoidCallback onSeekForward;
  final ValueChanged<double> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onSeekBackward,
          icon: const Icon(Icons.replay_10_rounded),
          tooltip: 'Back 10s',
        ),
        IconButton(
          onPressed: onPlayPause,
          icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
          iconSize: 34,
          tooltip: isPlaying ? 'Pause' : 'Play',
        ),
        IconButton(
          onPressed: onSeekForward,
          icon: const Icon(Icons.forward_10_rounded),
          tooltip: 'Forward 10s',
        ),
        const Spacer(),
        DropdownButton<double>(
          value: currentSpeed,
          items: availableSpeeds
              .map(
                (double speed) => DropdownMenuItem<double>(
                  value: speed,
                  child: Text('${speed}x'),
                ),
              )
              .toList(growable: false),
          onChanged: (double? value) {
            if (value != null) {
              onSpeedChanged(value);
            }
          },
        ),
      ],
    );
  }
}
