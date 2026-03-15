import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/biometric_service.dart';
import '../../domain/pin_repository.dart';

class AuthState extends Equatable {
  const AuthState({
    required this.isLoading,
    required this.isPinSet,
    required this.isAuthenticated,
    required this.canUseBiometric,
    required this.biometricLabel,
    this.errorMessage,
  });

  const AuthState.initial()
      : isLoading = true,
        isPinSet = false,
        isAuthenticated = false,
        canUseBiometric = false,
        biometricLabel = 'Face ID',
        errorMessage = null;

  final bool isLoading;
  final bool isPinSet;
  final bool isAuthenticated;
  final bool canUseBiometric;
  final String biometricLabel;
  final String? errorMessage;

  AuthState copyWith({
    bool? isLoading,
    bool? isPinSet,
    bool? isAuthenticated,
    bool? canUseBiometric,
    String? biometricLabel,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isPinSet: isPinSet ?? this.isPinSet,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      canUseBiometric: canUseBiometric ?? this.canUseBiometric,
      biometricLabel: biometricLabel ?? this.biometricLabel,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        isLoading,
        isPinSet,
        isAuthenticated,
        canUseBiometric,
        biometricLabel,
        errorMessage,
      ];
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._pinRepository, this._biometricService)
      : super(const AuthState.initial()) {
    initialize();
  }

  final PinRepository _pinRepository;
  final BiometricService _biometricService;

  Future<void> initialize({bool tryBiometric = true}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bool isPinSet = await _pinRepository.hasPin();
      final List<BiometricType> availableBiometrics = isPinSet
          ? await _biometricService.getAvailableBiometrics()
          : const <BiometricType>[];
      final bool canUseBiometric = isPinSet &&
          availableBiometrics.isNotEmpty &&
          await _biometricService.canAuthenticate();
      final String biometricLabel =
          _biometricService.resolveBiometricLabel(availableBiometrics);

      state = state.copyWith(
        isLoading: false,
        isPinSet: isPinSet,
        isAuthenticated: false,
        canUseBiometric: canUseBiometric,
        biometricLabel: biometricLabel,
      );

      if (isPinSet && tryBiometric && canUseBiometric) {
        await unlockWithBiometric();
      }
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to initialize authentication.',
      );
    }
  }

  Future<void> unlockWithBiometric() async {
    if (!state.isPinSet) {
      return;
    }

    if (!state.canUseBiometric) {
      state = state.copyWith(
        errorMessage:
            '${state.biometricLabel} is not available. Use PIN or enable biometrics in device settings.',
      );
      return;
    }

    try {
      final bool isAuthenticated = await _biometricService.authenticate();
      if (isAuthenticated) {
        state = state.copyWith(isAuthenticated: true, clearError: true);
      }
    } catch (_) {
      state = state.copyWith(
          errorMessage: 'Biometric authentication failed. Use your PIN.');
    }
  }

  Future<void> setPin(String rawPin) async {
    if (!_isValidPin(rawPin)) {
      state = state.copyWith(
        errorMessage:
            'PIN must contain ${AppConstants.minPinLength}-${AppConstants.maxPinLength} digits.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _pinRepository.savePinHash(_hashPin(rawPin));
      final List<BiometricType> availableBiometrics =
          await _biometricService.getAvailableBiometrics();
      final bool canUseBiometric = availableBiometrics.isNotEmpty &&
          await _biometricService.canAuthenticate();
      final String biometricLabel =
          _biometricService.resolveBiometricLabel(availableBiometrics);

      state = state.copyWith(
        isLoading: false,
        isPinSet: true,
        isAuthenticated: true,
        canUseBiometric: canUseBiometric,
        biometricLabel: biometricLabel,
      );
    } catch (_) {
      state =
          state.copyWith(isLoading: false, errorMessage: 'Failed to save PIN.');
    }
  }

  Future<void> unlockWithPin(String rawPin) async {
    if (!_isValidPin(rawPin)) {
      state = state.copyWith(
        errorMessage:
            'PIN must contain ${AppConstants.minPinLength}-${AppConstants.maxPinLength} digits.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final bool verified =
          await _pinRepository.verifyPinHash(_hashPin(rawPin));
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: verified,
        errorMessage: verified ? null : 'Invalid PIN.',
      );
    } catch (_) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Failed to verify PIN.');
    }
  }

  void lock() {
    state = state.copyWith(isAuthenticated: false, clearError: true);
  }

  void onAppResumed() {
    if (state.isPinSet && state.isAuthenticated) {
      lock();
    }
  }

  bool _isValidPin(String pin) {
    final bool validLength = pin.length >= AppConstants.minPinLength &&
        pin.length <= AppConstants.maxPinLength;
    final bool digitsOnly = RegExp(r'^\d+$').hasMatch(pin);
    return validLength && digitsOnly;
  }

  String _hashPin(String pin) {
    final Digest digest = sha256.convert(utf8.encode(pin));
    return digest.toString();
  }
}

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (Ref ref) =>
      AuthController(getIt<PinRepository>(), getIt<BiometricService>()),
);
