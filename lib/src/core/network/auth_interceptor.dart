import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// Interceptor de Dio para inyectar automáticamente el token JWT en las cabeceras HTTP.
/// Maneja también el saneamiento en caso de token expirado o inválido (HTTP 401).
class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService secureStorage;
  final void Function()? onSessionExpired;

  AuthInterceptor({
    required this.secureStorage,
    this.onSessionExpired,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Endpoints públicos que no requieren autorización Bearer
    final isPublicEndpoint = options.path.contains('/auth/login') ||
        options.path.contains('/api/auth/token/');

    if (!isPublicEndpoint) {
      final token = await secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Cabeceras estándar para interoperabilidad con FastAPI
    options.headers['Accept'] = 'application/json';
    options.headers['X-Client-Platform'] = 'Flutter-Mobile-Field';

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Sesión revocada o token expirado en FastAPI
      secureStorage.clearAll();
      onSessionExpired?.call();
    }
    return handler.next(err);
  }
}
