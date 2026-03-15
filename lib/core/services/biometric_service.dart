import 'package:local_auth/local_auth.dart';

import '../errors/exceptions.dart';

class BiometricService {
  BiometricService({LocalAuthentication? localAuthentication})
      : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  Future<bool> canAuthenticate() async {
    final bool canCheckBiometrics =
        await _localAuthentication.canCheckBiometrics;
    final bool isSupported = await _localAuthentication.isDeviceSupported();
    return canCheckBiometrics && isSupported;
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return _localAuthentication.getAvailableBiometrics();
    } catch (_) {
      return const <BiometricType>[];
    }
  }

  String resolveBiometricLabel(List<BiometricType> availableBiometrics) {
    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    }
    if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }
    if (availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometrics';
  }

  Future<bool> authenticate() async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: 'Authenticate to unlock NANDX',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (error) {
      throw AuthenticationException('Biometric authentication failed');
    }
  }
}
