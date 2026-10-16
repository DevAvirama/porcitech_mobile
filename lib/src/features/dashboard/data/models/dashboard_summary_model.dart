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

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalPorcinos: json['total_porcinos'] as int? ?? json['total_animals'] as int? ?? 0,
      alertasSanitarias: json['alertas_sanitarias'] as int? ?? json['total_alerts'] as int? ?? 0,
      porcinosEnCeba: json['porcinos_en_ceba'] as int? ?? 0,
      hembrasGestacion: json['hembras_gestacion'] as int? ?? 0,
      partosMes: json['partos_mes'] as int? ?? 0,
      gdpPromedioGramoDia: (json['gdp_promedio_gramo_dia'] as num?)?.toDouble() ?? 0.0,
      registrosPendientesSync: json['registros_pendientes_sync'] as int? ?? json['pending_sync'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_porcinos': totalPorcinos,
      'alertas_sanitarias': alertasSanitarias,
      'porcinos_en_ceba': porcinosEnCeba,
      'hembras_gestacion': hembrasGestacion,
      'partos_mes': partosMes,
      'gdp_promedio_gramo_dia': gdpPromedioGramoDia,
      'registros_pendientes_sync': registrosPendientesSync,
    };
  }
}