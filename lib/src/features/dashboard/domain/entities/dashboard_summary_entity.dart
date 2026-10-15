import 'package:equatable/equatable.dart';

/// Entidad inmutable con el resumen operacional y zootécnico del galpón/granja.
class DashboardSummaryEntity extends Equatable {
  final int totalPorcinos;
  final int alertasSanitarias;
  final int porcinosEnCeba;
  final int hembrasGestacion;
  final int partosMes;
  final double gdpPromedioGramoDia;
  final int registrosPendientesSync;

  const DashboardSummaryEntity({
    required this.totalPorcinos,
    required this.alertasSanitarias,
    required this.porcinosEnCeba,
    required this.hembrasGestacion,
    required this.partosMes,
    required this.gdpPromedioGramoDia,
    required this.registrosPendientesSync,
  });

  @override
  List<Object?> get props => [
        totalPorcinos,
        alertasSanitarias,
        porcinosEnCeba,
        hembrasGestacion,
        partosMes,
        gdpPromedioGramoDia,
        registrosPendientesSync,
      ];
}
