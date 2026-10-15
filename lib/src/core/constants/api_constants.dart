/// Constantes de configuración de red y endpoints para la API FastAPI de PorciTech.
/// Flutter se comunica exclusivamente con la API REST vía HTTP/HTTPS.
class ApiConstants {
  ApiConstants._();

  /// URL Base configurable según el entorno (desarrollo local / staging / producción).
  /// Por defecto apunta al host de desarrollo del backend FastAPI.
  static const String defaultBaseUrl = 'https://api.porcitech.agro.co';
  static const String localDevBaseUrl = 'http://10.0.2.2:8000'; // Emulador Android

  /// Timeouts optimizados para redes de campo con latencia moderada.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  // --- Endpoints de Autenticación ---
  static const String loginToken = '/api/auth/token/';
  static const String userProfile = '/api/users/profile/';

  // --- Endpoints de Dashboard ---
  static const String dashboardSummary = '/api/dashboard/summary/';

  // --- Endpoints de Lotes y Porcinos ---
  static const String porcinos = '/api/porcinos/';
  static String porcinoById(int id) => '/api/porcinos/$id/';
  static String porcinoByQr(String codigo) => '/api/porcinos/qr/$codigo/';
  static const String lotes = '/api/lotes/';

  // --- Endpoints de Pesaje y Visión Artificial ---
  static const String pesos = '/api/pesos/';
  static const String iaEstimarPeso = '/api/ia/estimar-peso/';

  // --- Endpoints de Sanidad y Trazabilidad Farmacológica ---
  static const String eventosSanitarios = '/api/eventos-sanitarios/';
  static const String inventarioDescuento = '/api/inventario/descuento/';

  // --- Endpoints de Control Reproductivo ---
  static const String eventosReproductivos = '/api/eventos-reproductivos/';

  // --- Endpoints de Sincronización Offline ---
  static const String syncOfflineQueue = '/api/sync/offline-queue/';
}
