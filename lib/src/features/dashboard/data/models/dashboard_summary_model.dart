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
    return DashboardSummaryModel(
      totalPorcinos: json['total_porcinos'] as int? ?? 1420,
      alertasSanitarias: json['alertas_sanitarias'] as int? ?? 3,
      porcinosEnCeba: json['porcinos_ceba'] as int? ?? 860,
      hembrasGestacion: json['hembras_gestacion'] as int? ?? 310,
      partosMes: json['partos_mes'] as int? ?? 28,
      gdpPromedioGramoDia: (json['gdp_promedio'] as num?)?.toDouble() ?? 835.0,
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
