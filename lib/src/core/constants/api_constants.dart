/// Constantes de configuración de red y endpoints para la API FastAPI de PorciTech.
/// Flutter se comunica exclusivamente con la API REST vía HTTP/HTTPS.
class ApiConstants {
  ApiConstants._();

  /// URL Base configurable mediante `--dart-define=API_BASE_URL=...` o por defecto la IP local/VM.
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.32.134:8000/api/v1',
  );
  static const String localDevBaseUrl = 'http://10.0.2.2:8000/api/v1'; // Emulador Android
  static const String localHostBaseUrl = 'http://127.0.0.1:8000/api/v1'; // Host directo

  /// Timeouts optimizados para redes de campo con latencia moderada.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  // --- Estado del Sistema ---
  static const String systemStatus = '/status';

  // --- Endpoints de Autenticación y Perfil ---
  static const String loginToken = '/auth/login';
  static const String userProfile = '/auth/me';

  // --- Endpoints de Dashboard ---
  static const String dashboardSummary = '/dashboard/kpis';
  static const String dashboardAlerts = '/dashboard/alerts';
  static const String dashboardRecentActivity = '/dashboard/recent-activity';

  // --- Endpoints de Corrales y Porcinos ---
  static const String porcinos = '/animales';
  static String porcinoById(dynamic id) => '/animales/$id';
  static String porcinoByQr(String codigo) => '/animales/qr/${Uri.encodeComponent(codigo)}';
  static const String lotes = '/corrales';
  static String loteById(dynamic id) => '/corrales/$id';

  // --- Endpoints de Pesaje y Visión Artificial ---
  static const String pesos = '/pesajes/manual';
  static const String iaEstimarPeso = '/pesajes/vision';
  static const String camaraRtsp = '/pesajes/camara-rtsp';
  static const String capturarEnVivo = '/pesajes/capturar-en-vivo';
  static String pesajesPorAnimal(dynamic id) => '/pesajes/animal/$id';
  static String gmdPorCorral(dynamic id) => '/pesajes/corral/$id/gmd';

  // --- Endpoints de Alimentación y Raciones ---
  static const String raciones = '/alimentacion/raciones';

  // --- Endpoints de Inventario y Bodega ---
  static const String inventarioCategorias = '/inventario/categorias';
  static const String inventarioItems = '/inventario/items';
  static const String inventarioDescuento = '/inventario/movimientos';

  // --- Endpoints de Sanidad, Retiros y Bioseguridad ---
  static const String eventosSanitarios = '/sanidad/tratamientos';
  static const String alertasRetiro = '/sanidad/alertas-retiro';
  static const String bioseguridadProtocolos = '/sanidad/bioseguridad/protocolos';
  static const String bioseguridadEjecuciones = '/sanidad/bioseguridad/ejecuciones';

  // --- Endpoints de Control Reproductivo ---
  static const String eventosReproductivos = '/reproduccion/servicios';
  static String servicioReproductivoById(dynamic id) => '/reproduccion/servicios/$id';
  static const String partos = '/reproduccion/partos';
  static const String destetes = '/reproduccion/destetes';

  // --- Endpoints de Sincronización Offline ---
  static const String syncOfflineQueue = '/pesajes/manual';
}
