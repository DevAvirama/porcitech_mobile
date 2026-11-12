/// Excepción base del ecosistema PorciTech para la capa de datos e infraestructura.
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => 'AppException: $message (código: $statusCode)';
}

/// Solicitud malformada o validación fallida (HTTP 400).
class BadRequestException extends AppException {
  const BadRequestException(super.message, [super.statusCode = 400]);
}

/// Token ausente, inválido o expirado (HTTP 401).
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'No autorizado.', super.statusCode = 401]);
}

/// Usuario sin rol adecuado (HTTP 403).
class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'Acceso denegado.', super.statusCode = 403]);
}

/// Recurso inexistente (HTTP 404).
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Recurso no encontrado.', super.statusCode = 404]);
}

/// Error interno del backend FastAPI (HTTP 500).
class ServerException extends AppException {
  const ServerException([super.message = 'Error en el servidor de PorciTech.', super.statusCode = 500]);
}

/// Ausencia de red física o timeout de conexión en corral.
class NoInternetException extends AppException {
  const NoInternetException([super.message = 'Sin conexión a internet.']);
}

/// Error al leer o escribir en Secure Storage o SharedPreferences.
class CacheException extends AppException {
  const CacheException(super.message);
}
