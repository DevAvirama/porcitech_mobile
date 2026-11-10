import '../../domain/entities/dashboard_summary_entity.dart';

class DashboardSummaryModel extends DashboardSummaryEntity {
  const DashboardSummaryModel({
    required super.totalPorcinos,
    super.totalCorralesActivos = 0,
    super.pesoPromedioGranjaKg = 0.0,
    required super.alertasSanitarias,
    super.alertasInventarioStock = 0,
    super.tasaOcupacionPorcentaje = 0.0,
    required super.porcinosEnCeba,
    required super.hembrasGestacion,
    required super.partosMes,
    required super.gdpPromedioGramoDia,
    required super.registrosPendientesSync,
    super.alertas = const [],
    super.actividadReciente = const [],
  });

  factory DashboardSummaryModel.fromJson(
    Map<String, dynamic> json, {
    int pendingSync = 0,
    List<DashboardAlertEntity> alertas = const [],
    List<RecentActivityEntity> actividadReciente = const [],
  }) {
    final dist = (json['distribucion_etapas'] is Map<String, dynamic>)
        ? json['distribucion_etapas'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawGmd = (json['gmd_promedio_kg'] as num?)?.toDouble() ??
        (json['gdp_promedio'] as num?)?.toDouble();
    final double gdpGramoDia = rawGmd != null
        ? (rawGmd > 0 && rawGmd < 10.0 ? rawGmd * 1000.0 : rawGmd)
        : 0.0;

    final int cebaCount = ((dist['ceba'] as num?)?.toInt() ?? 0) +
        ((dist['engorde'] as num?)?.toInt() ?? 0) +
        ((dist['levante'] as num?)?.toInt() ?? 0);

    final int gestacionCount = ((dist['gestacion'] as num?)?.toInt() ?? 0) +
        ((dist['maternidad'] as num?)?.toInt() ?? 0);

    return DashboardSummaryModel(
      totalPorcinos: (json['total_animales'] as num?)?.toInt() ??
          (json['total_porcinos'] as num?)?.toInt() ??
          0,
      totalCorralesActivos: (json['total_corrales_activos'] as num?)?.toInt() ?? 0,
      pesoPromedioGranjaKg:
          (json['peso_promedio_granja_kg'] as num?)?.toDouble() ?? 0.0,
      alertasSanitarias: (json['alertas_sanitarias'] as num?)?.toInt() ?? 0,
      alertasInventarioStock:
          (json['alertas_inventario_stock'] as num?)?.toInt() ?? 0,
      tasaOcupacionPorcentaje:
          (json['tasa_ocupacion_porcentaje'] as num?)?.toDouble() ?? 0.0,
      porcinosEnCeba: cebaCount > 0
          ? cebaCount
          : ((json['porcinos_ceba'] as num?)?.toInt() ?? 0),
      hembrasGestacion: gestacionCount > 0
          ? gestacionCount
          : ((json['hembras_gestacion'] as num?)?.toInt() ?? 0),
      partosMes: (dist['maternidad'] as num?)?.toInt() ??
          (json['partos_mes'] as num?)?.toInt() ??
          0,
      gdpPromedioGramoDia: gdpGramoDia,
      registrosPendientesSync: pendingSync,
      alertas: alertas,
      actividadReciente: actividadReciente,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_animales': totalPorcinos,
      'total_porcinos': totalPorcinos,
      'total_corrales_activos': totalCorralesActivos,
      'peso_promedio_granja_kg': pesoPromedioGranjaKg,
      'alertas_sanitarias': alertasSanitarias,
      'alertas_inventario_stock': alertasInventarioStock,
      'tasa_ocupacion_porcentaje': tasaOcupacionPorcentaje,
      'porcinos_ceba': porcinosEnCeba,
      'hembras_gestacion': hembrasGestacion,
      'partos_mes': partosMes,
      'gdp_promedio': gdpPromedioGramoDia,
    };
  }
}
