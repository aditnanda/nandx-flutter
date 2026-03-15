import 'package:get_it/get_it.dart';

import '../../features/auth/data/pin_repository_impl.dart';
import '../../features/auth/domain/pin_repository.dart';
import '../../features/file_browser/data/repositories/file_repository_impl.dart';
import '../../features/file_browser/domain/repositories/file_repository.dart';
import '../../features/file_browser/domain/services/file_sorting_service.dart';
import '../../features/file_operations/data/services/file_operation_service.dart';
import '../../features/player/data/services/video_cache_service.dart';
import '../../features/smb_connections/data/smb_repository_impl.dart';
import '../../features/smb_connections/domain/smb_repository.dart';
import '../services/biometric_service.dart';
import '../services/local_video_proxy_service.dart';
import '../services/secure_storage_service.dart';
import '../services/smb_session_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<SecureStorageService>()) {
    return;
  }

  getIt
    ..registerLazySingleton<SecureStorageService>(SecureStorageService.new)
    ..registerLazySingleton<BiometricService>(BiometricService.new)
    ..registerLazySingleton<PinRepository>(
      () => PinRepositoryImpl(getIt<SecureStorageService>()),
    )
    ..registerLazySingleton<SmbSessionService>(SmbSessionService.new)
    ..registerLazySingleton<SmbRepository>(
      () => SmbRepositoryImpl(
        getIt<SecureStorageService>(),
        getIt<SmbSessionService>(),
      ),
    )
    ..registerLazySingleton<FileRepository>(
      () => FileRepositoryImpl(getIt<SmbSessionService>()),
    )
    ..registerLazySingleton<FileSortingService>(FileSortingService.new)
    ..registerLazySingleton<FileOperationService>(
      () => FileOperationService(getIt<FileRepository>()),
    )
    ..registerLazySingleton<LocalVideoProxyService>(
      () => LocalVideoProxyService(getIt<SmbSessionService>()),
    )
    ..registerLazySingleton<VideoCacheService>(
      () => VideoCacheService(
        getIt<SmbSessionService>(),
        getIt<LocalVideoProxyService>(),
      ),
    );
}
