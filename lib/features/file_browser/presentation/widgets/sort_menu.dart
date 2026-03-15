import 'package:flutter/material.dart';

import '../../domain/entities/sort_mode.dart';

class SortMenu extends StatelessWidget {
  const SortMenu({
    required this.currentMode,
    required this.onChanged,
    super.key,
  });

  final SortMode currentMode;
  final ValueChanged<SortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortMode>(
      icon: const Icon(Icons.sort_rounded),
      tooltip: 'Sort files',
      onSelected: onChanged,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<SortMode>>[
        CheckedPopupMenuItem<SortMode>(
          value: SortMode.dynamic,
          checked: currentMode == SortMode.dynamic,
          child: const Text('Dynamic'),
        ),
        CheckedPopupMenuItem<SortMode>(
          value: SortMode.name,
          checked: currentMode == SortMode.name,
          child: const Text('Name'),
        ),
        CheckedPopupMenuItem<SortMode>(
          value: SortMode.createdAt,
          checked: currentMode == SortMode.createdAt,
          child: const Text('Created Date'),
        ),
      ],
    );
  }
}
