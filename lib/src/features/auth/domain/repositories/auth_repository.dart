import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Contrato abstracto para el repositorio de autenticación en PorciTech.
abstract class AuthRepository {
  /// Inicia sesión contra FastAPI `POST /api/auth/token/`.
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  /// Obtiene la sesión actual persistida en SecureStorage.
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Cierra la sesión activa y purga el SecureStorage.
  Future<Either<Failure, void>> logout();
}
