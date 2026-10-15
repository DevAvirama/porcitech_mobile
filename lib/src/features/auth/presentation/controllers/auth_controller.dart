import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcitech_mobile/src/core/di/core_providers.dart';
import 'package:porcitech_mobile/src/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:porcitech_mobile/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:porcitech_mobile/src/features/auth/domain/entities/user_entity.dart';
import 'package:porcitech_mobile/src/features/auth/domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRemoteDataSourceImpl(dioClient);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final cacheService = ref.watch(localCacheServiceProvider);

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    secureStorage: secureStorage,
    cacheService: cacheService,
  );
});

class AuthState {
  final bool isLoading;
  final UserEntity? user;
  final String? errorMessage;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserEntity? user,
    String? errorMessage,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Verificación asíncrona de sesión previa
    Future.microtask(() => checkCurrentSession());
    return const AuthState();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> checkCurrentSession() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.getCurrentUser();
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: user != null,
      ),
    );
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.login(email: email, password: password);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
          isAuthenticated: false,
        );
        return false;
      },
      (user) {
        state = state.copyWith(
          isLoading: false,
          user: user,
          isAuthenticated: true,
          errorMessage: null,
        );
        return true;
      },
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    state = const AuthState();
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
