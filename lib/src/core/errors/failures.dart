import 'package:equatable/equatable.dart';

/// Clase base inmutable para todos los fallos del dominio en PorciTech.
/// Usada en combinación con `fpdart` en retornos `Either<Failure, T>`.
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, [this.statusCode]);

  @override
  List<Object?> get props => [message, statusCode];
}

/// Fallo por error de validación o solicitud incorrecta (HTTP 400).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.statusCode = 400]);
}

/// Fallo por falta de credenciales o sesión expirada (HTTP 401).
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Sesión no autorizada o token expirado.', super.statusCode = 401]);
}

/// Fallo por permisos insuficientes del operario/usuario (HTTP 403).
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'Acceso denegado: permisos insuficientes.', super.statusCode = 403]);
}

/// Fallo por recurso no encontrado en el servidor (HTTP 404).
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'El registro o animal solicitado no fue encontrado.', super.statusCode = 404]);
}

/// Fallo de servidor interno en FastAPI (HTTP 500).
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error interno en el servidor de PorciTech.', super.statusCode = 500]);
}

/// Fallo por falta de conectividad a Internet o red en galpón.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión a la red de granja. Operando en modo local.']);
}

/// Fallo en almacenamiento local seguro o caché en disco.
class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

/// Fallo por violación de reglas zootécnicas (p. ej., registrar parto en macho).
class ZootechnicalFailure extends Failure {
  const ZootechnicalFailure(super.message);
}

/// Fallo inesperado general.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Ocurrió un error inesperado.']);
}
