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
    if (cacheService.isOfflineModeEnabled()) {
      return _offlineLogin(email);
    }

    try {
      final userModel = await remoteDataSource.login(
        email: email,
        password: password,
      );

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
      final offline = await _offlineLogin(email);
      return offline.isRight() ? offline : Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  /// Ingreso sin red: solo se permite reabrir la sesión del ÚLTIMO usuario que se autenticó
  /// en línea en este dispositivo, si su token real sigue guardado (no cerró sesión ni fue
  /// revocado con 401). No acepta credenciales de terceros ni fabrica tokens.
  Future<Either<Failure, UserEntity>> _offlineLogin(String email) async {
    final cachedUser = await secureStorage.getUserData();
    final cachedEmail = cachedUser['email']?.trim().toLowerCase() ?? '';
    final token = await secureStorage.getAccessToken();
    if (cachedEmail.isEmpty || token == null || token.isEmpty) {
      return const Left(
        AuthFailure('Sin conexión: inicie sesión en línea al menos una vez en este dispositivo.'),
      );
    }
    if (cachedEmail != email.trim().toLowerCase()) {
      return const Left(
        AuthFailure('Sin conexión solo puede ingresar el último usuario autenticado en este dispositivo.'),
      );
    }
    return Right(
      UserModel(
        id: 1,
        email: cachedUser['email']!,
        name: cachedUser['name'] ?? 'Operario de Campo',
        role: cachedUser['role'] ?? 'operario',
        token: token,
        granja: 'Unidad Porcina SENA (Offline)',
      ),
    );
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
          name: userData['name'] ?? 'Operario Unidad Porcina',
          role: userData['role'] ?? 'operario',
          token: token,
          granja: 'Unidad Porcina Tecnificada • SENA',
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
