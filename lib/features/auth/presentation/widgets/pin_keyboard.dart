import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class PinKeyboard extends StatelessWidget {
  const PinKeyboard({
    required this.currentPin,
    required this.onNumberPressed,
    required this.onBackspace,
    required this.onClear,
    required this.onSubmit,
    super.key,
  });

  final String currentPin;
  final ValueChanged<int> onNumberPressed;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(
            AppConstants.maxPinLength,
            (int index) => Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < currentPin.length
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            ...List<Widget>.generate(
              9,
              (int index) => _DigitButton(
                digit: index + 1,
                onPressed: () => onNumberPressed(index + 1),
              ),
            ),
            _ActionButton(label: 'Clear', onPressed: onClear),
            _DigitButton(
              digit: 0,
              onPressed: () => onNumberPressed(0),
            ),
            _ActionButton(label: '⌫', onPressed: onBackspace),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed:
              currentPin.length >= AppConstants.minPinLength ? onSubmit : null,
          icon: const Icon(Icons.lock_open_rounded),
          label: const Text('Submit'),
        ),
      ],
    );
  }
}

class _DigitButton extends StatelessWidget {
  const _DigitButton({required this.digit, required this.onPressed});

  final int digit;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text('$digit', style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );
  }
}
