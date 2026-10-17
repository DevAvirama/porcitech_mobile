/// Constantes de configuración de red y endpoints para la API FastAPI de PorciTech.
/// Flutter se comunica exclusivamente con la API REST vía HTTP/HTTPS.
class ApiConstants {
  ApiConstants._();

  /// URL Base configurable según el entorno (desarrollo local / VM / staging / producción).
  /// Por defecto apunta a la IP de la máquina virtual / red de desarrollo.
  static const String defaultBaseUrl = 'http://192.168.32.134:8000/api/v1';
  static const String localDevBaseUrl = 'http://10.0.2.2:8000/api/v1'; // Emulador Android
  static const String localHostBaseUrl = 'http://127.0.0.1:8000/api/v1'; // Host directo

  /// Timeouts optimizados para redes de campo con latencia moderada.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  // --- Endpoints de Autenticación y Perfil ---
  static const String loginToken = '/auth/login';
  static const String userProfile = '/usuarios/me';

  // --- Endpoints de Dashboard ---
  static const String dashboardSummary = '/dashboard/kpis';

  // --- Endpoints de Corrales y Porcinos ---
  static const String porcinos = '/animales';
  static String porcinoById(dynamic id) => '/animales/$id';
  static String porcinoByQr(String codigo) => '/animales/qr/$codigo';
  static const String lotes = '/corrales';

  // --- Endpoints de Pesaje y Visión Artificial ---
  static const String pesos = '/pesajes/manual';
  static const String iaEstimarPeso = '/pesajes/vision';
  static const String camaraRtsp = '/pesajes/camara-rtsp';
  static String pesajesPorAnimal(dynamic id) => '/pesajes/animal/$id';

  // --- Endpoints de Sanidad y Trazabilidad Farmacológica ---
  static const String eventosSanitarios = '/sanidad/tratamientos';
  static const String inventarioDescuento = '/inventario/movimientos';

  // --- Endpoints de Control Reproductivo ---
  static const String eventosReproductivos = '/reproduccion/servicios';

  // --- Endpoints de Sincronización Offline ---
  static const String syncOfflineQueue = '/pesajes/manual';
}
