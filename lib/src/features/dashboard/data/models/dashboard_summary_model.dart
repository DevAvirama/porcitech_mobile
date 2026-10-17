import '../../domain/entities/dashboard_summary_entity.dart';

class DashboardSummaryModel extends DashboardSummaryEntity {
  const DashboardSummaryModel({
    required super.totalPorcinos,
    required super.alertasSanitarias,
    required super.porcinosEnCeba,
    required super.hembrasGestacion,
    required super.partosMes,
    required super.gdpPromedioGramoDia,
    required super.registrosPendientesSync,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json, {int pendingSync = 0}) {
    final dist = (json['distribucion_etapas'] is Map<String, dynamic>)
        ? json['distribucion_etapas'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawGmd = (json['gmd_promedio_kg'] as num?)?.toDouble() ??
        (json['gdp_promedio'] as num?)?.toDouble();
    final double gdpGramoDia = rawGmd != null
        ? (rawGmd < 10.0 ? rawGmd * 1000.0 : rawGmd)
        : 810.0;

    return DashboardSummaryModel(
      totalPorcinos: (json['total_animales'] as num?)?.toInt() ??
          (json['total_porcinos'] as num?)?.toInt() ??
          0,
      alertasSanitarias: (json['alertas_sanitarias'] as num?)?.toInt() ?? 0,
      porcinosEnCeba: (dist['engorde'] as num?)?.toInt() ??
          (json['porcinos_ceba'] as num?)?.toInt() ??
          0,
      hembrasGestacion: (dist['gestacion'] as num?)?.toInt() ??
          (json['hembras_gestacion'] as num?)?.toInt() ??
          0,
      partosMes: (dist['maternidad'] as num?)?.toInt() ??
          (json['partos_mes'] as num?)?.toInt() ??
          0,
      gdpPromedioGramoDia: gdpGramoDia,
      registrosPendientesSync: pendingSync,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_porcinos': totalPorcinos,
      'alertas_sanitarias': alertasSanitarias,
      'porcinos_ceba': porcinosEnCeba,
      'hembras_gestacion': hembrasGestacion,
      'partos_mes': partosMes,
      'gdp_promedio': gdpPromedioGramoDia,
    };
  }
}
