import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../controllers/auth_controller.dart';
import '../widgets/pin_keyboard.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String? _firstPin;

  @override
  Widget build(BuildContext context) {
    final AuthState state = ref.watch(authControllerProvider);
    final ThemeData theme = Theme.of(context);

    ref.listen<AuthState>(authControllerProvider,
        (AuthState? _, AuthState next) {
      if (next.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final bool isCreatePinFlow = !state.isPinSet;
    final String title = isCreatePinFlow
        ? (_firstPin == null ? 'Set Your PIN' : 'Confirm Your PIN')
        : 'Unlock NANDX';

    final String subtitle = isCreatePinFlow
        ? 'Create a ${AppConstants.minPinLength}-${AppConstants.maxPinLength} digit PIN.'
        : 'Use biometrics or enter your PIN to continue.';
    final String biometricButtonLabel = 'Use ${state.biometricLabel}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFF4FAF7), Color(0xFFE7F4EF)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'assets/branding/nandx_brand_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const BrandLogo(height: 64),
                            const SizedBox(height: 14),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (state.isPinSet) ...<Widget>[
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonalIcon(
                                  onPressed: state.isLoading
                                      ? null
                                      : () => ref
                                          .read(authControllerProvider.notifier)
                                          .unlockWithBiometric(),
                                  icon: Icon(
                                      _biometricIcon(state.biometricLabel)),
                                  label: Text(biometricButtonLabel),
                                ),
                              ),
                              if (!state.canUseBiometric)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '${state.biometricLabel} is currently unavailable on this device.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 18),
                            PinKeyboard(
                              currentPin: _pin,
                              onNumberPressed: _onNumberPressed,
                              onBackspace: _onBackspace,
                              onClear: _onClear,
                              onSubmit: () => _onSubmit(isCreatePinFlow),
                            ),
                            if (state.isLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 20),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _biometricIcon(String biometricLabel) {
    if (biometricLabel == 'Face ID') {
      return Icons.face_retouching_natural_rounded;
    }
    if (biometricLabel == 'Fingerprint') {
      return Icons.fingerprint_rounded;
    }
    return Icons.verified_user_rounded;
  }

  void _onNumberPressed(int number) {
    if (_pin.length >= AppConstants.maxPinLength) {
      return;
    }
    setState(() {
      _pin = '$_pin$number';
    });
  }

  void _onBackspace() {
    if (_pin.isEmpty) {
      return;
    }
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _onClear() {
    setState(() {
      _pin = '';
    });
  }

  Future<void> _onSubmit(bool isCreatePinFlow) async {
    if (!isCreatePinFlow) {
      await ref.read(authControllerProvider.notifier).unlockWithPin(_pin);
      _onClear();
      return;
    }

    if (_firstPin == null) {
      if (_pin.length < AppConstants.minPinLength ||
          _pin.length > AppConstants.maxPinLength) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN length must be 4 to 6 digits.')),
        );
        return;
      }

      setState(() {
        _firstPin = _pin;
        _pin = '';
      });
      return;
    }

    if (_pin != _firstPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN does not match. Try again.')),
      );
      setState(() {
        _firstPin = null;
        _pin = '';
      });
      return;
    }

    await ref.read(authControllerProvider.notifier).setPin(_pin);

    setState(() {
      _firstPin = null;
      _pin = '';
    });
  }
}
