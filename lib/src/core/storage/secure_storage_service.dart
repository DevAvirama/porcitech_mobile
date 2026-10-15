import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de almacenamiento seguro para credenciales críticas y tokens JWT.
/// Utiliza el KeyStore de Android y Keychain de iOS para máxima seguridad física en granja.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const String _keyAccessToken = 'porcitech_access_token';
  static const String _keyRefreshToken = 'porcitech_refresh_token';
  static const String _keyUserEmail = 'porcitech_user_email';
  static const String _keyUserRole = 'porcitech_user_role';
  static const String _keyUserName = 'porcitech_user_name';

  /// Guarda el par de tokens de autenticación JWT.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
  }

  /// Obtiene el access token para inyección en `Authorization: Bearer <token>`.
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// Obtiene el refresh token.
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Guarda la información básica del usuario logueado en sesión.
  Future<void> saveUserData({
    required String email,
    required String name,
    required String role,
  }) async {
    await _storage.write(key: _keyUserEmail, value: email);
    await _storage.write(key: _keyUserName, value: name);
    await _storage.write(key: _keyUserRole, value: role);
  }

  /// Retorna los datos básicos del usuario.
  Future<Map<String, String?>> getUserData() async {
    final email = await _storage.read(key: _keyUserEmail);
    final name = await _storage.read(key: _keyUserName);
    final role = await _storage.read(key: _keyUserRole);
    return {
      'email': email,
      'name': name,
      'role': role,
    };
  }

  /// Verifica si existe un token de sesión activo.
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Limpia por completo las credenciales seguras (cierre de sesión).
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
