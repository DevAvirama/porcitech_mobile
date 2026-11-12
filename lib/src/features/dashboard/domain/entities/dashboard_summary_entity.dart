import 'package:equatable/equatable.dart';

class DashboardAlertEntity extends Equatable {
  final String id;
  final String nivel; // 'warning' | 'danger' | 'info'
  final String modulo; // 'sanidad' | 'inventario' | 'manejo'
  final String mensaje;
  final String accionSugerida;

  const DashboardAlertEntity({
    required this.id,
    required this.nivel,
    required this.modulo,
    required this.mensaje,
    required this.accionSugerida,
  });

  @override
  List<Object?> get props => [id, nivel, modulo, mensaje, accionSugerida];
}

class RecentActivityEntity extends Equatable {
  final String id;
  final String tipo; // 'pesaje' | 'sanidad' | 'alimentacion' | 'inventario' | 'animal'
  final String titulo;
  final String descripcion;
  final DateTime tiempo;
  final String usuario;

  const RecentActivityEntity({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.tiempo,
    required this.usuario,
  });

  @override
  List<Object?> get props => [id, tipo, titulo, descripcion, tiempo, usuario];
}

/// Entidad inmutable con el resumen operacional y zootécnico del galpón/granja.
class DashboardSummaryEntity extends Equatable {
  final int totalPorcinos;
  final int totalCorralesActivos;
  final double pesoPromedioGranjaKg;
  final int alertasSanitarias;
  final int alertasInventarioStock;
  final double tasaOcupacionPorcentaje;
  final int porcinosEnCeba;
  final int hembrasGestacion;
  final int partosMes;
  final double gdpPromedioGramoDia;
  final int registrosPendientesSync;
  final List<DashboardAlertEntity> alertas;
  final List<RecentActivityEntity> actividadReciente;

  const DashboardSummaryEntity({
    required this.totalPorcinos,
    this.totalCorralesActivos = 0,
    this.pesoPromedioGranjaKg = 0.0,
    required this.alertasSanitarias,
    this.alertasInventarioStock = 0,
    this.tasaOcupacionPorcentaje = 0.0,
    required this.porcinosEnCeba,
    required this.hembrasGestacion,
    required this.partosMes,
    required this.gdpPromedioGramoDia,
    required this.registrosPendientesSync,
    this.alertas = const [],
    this.actividadReciente = const [],
  });

  @override
  List<Object?> get props => [
        totalPorcinos,
        totalCorralesActivos,
        pesoPromedioGranjaKg,
        alertasSanitarias,
        alertasInventarioStock,
        tasaOcupacionPorcentaje,
        porcinosEnCeba,
        hembrasGestacion,
        partosMes,
        gdpPromedioGramoDia,
        registrosPendientesSync,
        alertas,
        actividadReciente,
      ];
}
