abstract class PinRepository {
  Future<bool> hasPin();
  Future<void> savePinHash(String hash);
  Future<bool> verifyPinHash(String hash);
  Future<void> clearPin();
}
