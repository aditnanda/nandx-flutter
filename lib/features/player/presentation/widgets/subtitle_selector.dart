import 'package:flutter/material.dart';

class SubtitleSelector extends StatelessWidget {
  const SubtitleSelector({
    required this.subtitles,
    required this.selectedSubtitlePath,
    required this.onSelected,
    required this.onPickExternal,
    super.key,
  });

  final Map<String, String> subtitles;
  final String? selectedSubtitlePath;
  final ValueChanged<MapEntry<String, String>> onSelected;
  final VoidCallback onPickExternal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: PopupMenuButton<MapEntry<String, String>>(
            tooltip: 'Select subtitles',
            itemBuilder: (BuildContext context) {
              if (subtitles.isEmpty) {
                return const <PopupMenuEntry<MapEntry<String, String>>>[
                  PopupMenuItem<MapEntry<String, String>>(
                    enabled: false,
                    child: Text('No subtitles detected'),
                  ),
                ];
              }

              return subtitles.entries
                  .map(
                    (MapEntry<String, String> item) =>
                        CheckedPopupMenuItem<MapEntry<String, String>>(
                      value: item,
                      checked: item.value == selectedSubtitlePath,
                      child: Text(item.key),
                    ),
                  )
                  .toList(growable: false);
            },
            onSelected: onSelected,
            child: const ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.subtitles_outlined),
              title: Text('Subtitles'),
              trailing: Icon(Icons.arrow_drop_down_rounded),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onPickExternal,
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('External'),
        ),
      ],
    );
  }
}
