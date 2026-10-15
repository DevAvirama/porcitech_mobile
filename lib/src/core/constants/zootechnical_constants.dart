/// Constantes zootécnicas y parámetros biológicos de la porcicultura tecnificada.
/// Integra estándares de Porkcolombia para Ganancia Diaria de Peso (GDP),
/// tiempos de retiro farmacológico y reglas biológicas de reproducción y ceba.
class ZootechnicalConstants {
  ZootechnicalConstants._();

  // --- Estándares de Ganancia Diaria de Peso (GDP) Porkcolombia (g/día) ---
  static const double gdpPreceboMin = 450.0; // g/día
  static const double gdpPreceboMeta = 550.0; // g/día
  static const double gdpLevanteMeta = 750.0; // g/día
  static const double gdpCebaMeta = 850.0; // g/día
  static const double gdpCebaOptimo = 920.0; // g/día

  // --- Estados Fisiológicos / Fases del Porcino ---
  static const String faseLactancia = 'Lactancia';
  static const String fasePrecebo = 'Precebo';
  static const String faseLevante = 'Levante';
  static const String faseCeba = 'Ceba';
  static const String faseGestacion = 'Gestación';
  static const String faseMaternidad = 'Maternidad';
  static const String faseVacia = 'Hembra Vacía';
  static const String faseVerraco = 'Reproductor Activo';

  // --- Estados Sanitarios del Porcino ---
  static const String estadoSano = 'Sano';
  static const String estadoEnTratamiento = 'En Tratamiento';
  static const String estadoEnfermo = 'Enfermo';
  static const String estadoCuarentena = 'Cuarentena';
  static const String estadoRetiroActivo = 'Retiro Farmacológico';

  // --- Tiempos de Retiro Farmacológico Predeterminados (Días) ---
  /// Según normatividad ICA / INVIMA para inocuidad alimentaria
  static const Map<String, int> tiemposRetiroDias = {
    'Oxitetraciclina L.A.': 28,
    'Tilmicosina': 14,
    'Ivermectina 1%': 28,
    'Amoxicilina Trihidrato': 10,
    'Penicilina G Procaínica': 7,
    'Flunixin Meglumine': 5,
    'Ketoprofeno 10%': 4,
    'Tiamulina': 5,
    'Hierro Dextrano': 0, // No requiere retiro
    'Vacuna Peste Porcina Clásica (PPC)': 21,
    'Vacuna Circovirus Porcino (PCV2)': 21,
    'Vacuna Mycoplasma hyopneumoniae': 21,
  };

  // --- Constantes Biológicas Reproductivas ---
  static const int duracionGestacionDias = 114; // 3 meses, 3 semanas, 3 días
  static const int duracionLactanciaDias = 21; // Destete típico tecnificado
  static const int edadPrimerServicioDias = 220; // ~7.5 meses
  static const double pesoMinimoPrimerServicioKg = 135.0; // kg

  // --- Parámetros de Parto en Cerda Tecnificada ---
  static const int metaNacidosVivos = 12;
  static const double metaPesoCamadaKg = 16.5;
  static const double pesoPromedioLechonNacimientoKg = 1.35;

  /// Calcula la Ganancia Diaria de Peso (GDP) en gramos por día entre dos pesajes.
  static double calcularGdpGramosDia({
    required double pesoAnteriorKg,
    required double pesoActualKg,
    required DateTime fechaAnterior,
    required DateTime fechaActual,
  }) {
    final dias = fechaActual.difference(fechaAnterior).inDays;
    if (dias <= 0) return 0.0;
    final gananciaKg = pesoActualKg - pesoAnteriorKg;
    return (gananciaKg / dias) * 1000.0;
  }

  /// Evalúa el desempeño de la GDP frente al estándar de Porkcolombia.
  static String clasificarDesempenoGdp(double gdpGramosDia, String fase) {
    if (fase == faseCeba) {
      if (gdpGramosDia >= gdpCebaOptimo) return 'Excelente (+Porkcolombia)';
      if (gdpGramosDia >= gdpCebaMeta) return 'Meta Óptima';
      if (gdpGramosDia >= gdpLevanteMeta) return 'Aceptable';
      return 'Bajo Rendimiento';
    } else if (fase == fasePrecebo) {
      if (gdpGramosDia >= gdpPreceboMeta) return 'Meta Óptima';
      if (gdpGramosDia >= gdpPreceboMin) return 'Aceptable';
      return 'Bajo Rendimiento';
    }
    return gdpGramosDia >= 700 ? 'Normal' : 'Requiere Revisión Nutricional';
  }
}
