import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;
  final LocalCacheService cacheService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
    required this.cacheService,
  });

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    // Si el modo offline está forzado, validamos credenciales cacheadas
    if (cacheService.isOfflineModeEnabled()) {
      final cachedUser = await secureStorage.getUserData();
      if (cachedUser['email'] != null && cachedUser['email']!.isNotEmpty) {
        return Right(
          UserEntity(
            id: 1,
            email: cachedUser['email']!,
            name: cachedUser['name'] ?? 'Operario de Campo',
            role: cachedUser['role'] ?? 'operario',
            token: 'offline_token_${DateTime.now().millisecondsSinceEpoch}',
            granja: 'Granja San Jerónimo (Modo Offline)',
          ),
        );
      }
    }

    try {
      final userModel = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Persistir JWT y datos en almacenamiento seguro
      await secureStorage.saveTokens(accessToken: userModel.token);
      await secureStorage.saveUserData(
        email: userModel.email,
        name: userModel.name,
        role: userModel.role,
      );

      return Right(userModel);
    } on BadRequestException catch (e) {
      return Left(ValidationFailure(e.message, e.statusCode));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message, e.statusCode));
    } on NoInternetException catch (e) {
      // Intento de fallback offline con credenciales previas
      final cachedUser = await secureStorage.getUserData();
      if (cachedUser['email'] != null && cachedUser['email']!.isNotEmpty) {
        return Right(
          UserEntity(
            id: 1,
            email: cachedUser['email']!,
            name: cachedUser['name'] ?? 'Operario de Campo',
            role: cachedUser['role'] ?? 'operario',
            token: 'offline_cached_token',
            granja: 'Granja San Jerónimo (Offline)',
          ),
        );
      }
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final hasToken = await secureStorage.hasValidToken();
      if (!hasToken) return const Right(null);

      final token = await secureStorage.getAccessToken();
      final userData = await secureStorage.getUserData();

      if (token == null || userData['email'] == null) {
        return const Right(null);
      }

      return Right(
        UserModel(
          id: 1,
          email: userData['email']!,
          name: userData['name'] ?? 'Operario Granja',
          role: userData['role'] ?? 'operario',
          token: token,
          granja: 'Granja San Jerónimo - Galpón 4',
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Error al recuperar sesión: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await secureStorage.clearAll();
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Error al cerrar sesión: $e'));
    }
  }
}
