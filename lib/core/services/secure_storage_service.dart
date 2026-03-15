import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/exceptions.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions:
                  IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;

  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error) {
      throw StorageException('Failed to write secure value for key: $key');
    }
  }

  Future<String?> read(String key) async {
    try {
      return _storage.read(key: key);
    } catch (error) {
      throw StorageException('Failed to read secure value for key: $key');
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (error) {
      throw StorageException('Failed to delete secure value for key: $key');
    }
  }

  Future<Map<String, String>> readAll() async {
    try {
      return _storage.readAll();
    } catch (error) {
      throw StorageException('Failed to read secure values');
    }
  }

  Future<void> writeJson({required String key, required Object data}) {
    return write(key: key, value: jsonEncode(data));
  }
}
