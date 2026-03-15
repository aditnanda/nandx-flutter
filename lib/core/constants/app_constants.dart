class AppConstants {
  const AppConstants._();

  static const String appName = 'NANDX';
  static const String appTagline = 'Secure SMB Streaming & File Vault';

  static const String pinHashKey = 'auth_pin_hash';
  static const String smbConnectionsKey = 'smb_connections';
  static const String smbPasswordPrefix = 'smb_password_';

  static const int minPinLength = 4;
  static const int maxPinLength = 6;
}
