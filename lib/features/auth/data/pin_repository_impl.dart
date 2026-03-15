import '../../../core/constants/app_constants.dart';
import '../../../core/services/secure_storage_service.dart';
import '../domain/pin_repository.dart';

class PinRepositoryImpl implements PinRepository {
  PinRepositoryImpl(this._secureStorageService);

  final SecureStorageService _secureStorageService;

  @override
  Future<bool> hasPin() async {
    return (await _secureStorageService.read(AppConstants.pinHashKey)) != null;
  }

  @override
  Future<void> savePinHash(String hash) {
    return _secureStorageService.write(
        key: AppConstants.pinHashKey, value: hash);
  }

  @override
  Future<bool> verifyPinHash(String hash) async {
    final String? storedHash =
        await _secureStorageService.read(AppConstants.pinHashKey);
    if (storedHash == null) {
      return false;
    }
    return storedHash == hash;
  }

  @override
  Future<void> clearPin() {
    return _secureStorageService.delete(AppConstants.pinHashKey);
  }
}
