import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/smb_connection.dart';
import '../../domain/smb_repository.dart';

class SmbState extends Equatable {
  const SmbState({
    required this.isLoading,
    required this.connections,
    this.errorMessage,
    this.connectingId,
  });

  const SmbState.initial()
      : isLoading = true,
        connections = const <SmbConnection>[],
        errorMessage = null,
        connectingId = null;

  final bool isLoading;
  final List<SmbConnection> connections;
  final String? errorMessage;
  final String? connectingId;

  SmbState copyWith({
    bool? isLoading,
    List<SmbConnection>? connections,
    String? errorMessage,
    String? connectingId,
    bool clearError = false,
  }) {
    return SmbState(
      isLoading: isLoading ?? this.isLoading,
      connections: connections ?? this.connections,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      connectingId: connectingId,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[isLoading, connections, errorMessage, connectingId];
}

class SmbController extends StateNotifier<SmbState> {
  SmbController(this._repository) : super(const SmbState.initial()) {
    loadConnections();
  }

  final SmbRepository _repository;

  Future<void> loadConnections() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final List<SmbConnection> items = await _repository.getConnections();
      items
          .sort((SmbConnection a, SmbConnection b) => a.name.compareTo(b.name));
      state = state.copyWith(
        isLoading: false,
        connections: items,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load SMB connections.',
      );
    }
  }

  Future<void> saveConnection(SmbConnection connection,
      {String? password}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.saveConnection(connection, password: password);
      await loadConnections();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save SMB connection.',
      );
    }
  }

  Future<void> deleteConnection(String id) async {
    state = state.copyWith(clearError: true);
    try {
      await _repository.deleteConnection(id);
      await loadConnections();
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to delete SMB connection.');
    }
  }

  Future<bool> connect(SmbConnection connection) async {
    state = state.copyWith(connectingId: connection.id, clearError: true);

    try {
      final bool ok = await _repository.connect(connection);
      state = state.copyWith(connectingId: null);
      if (!ok) {
        state =
            state.copyWith(errorMessage: 'Unable to connect to SMB server.');
      }
      return ok;
    } catch (_) {
      state = state.copyWith(
        connectingId: null,
        errorMessage: 'SMB connection error.',
      );
      return false;
    }
  }
}

final StateNotifierProvider<SmbController, SmbState> smbControllerProvider =
    StateNotifierProvider<SmbController, SmbState>(
  (Ref ref) => SmbController(getIt<SmbRepository>()),
);
