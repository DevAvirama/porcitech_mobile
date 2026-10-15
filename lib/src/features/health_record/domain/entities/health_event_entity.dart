import 'package:equatable/equatable.dart';

class HealthEventEntity extends Equatable {
  final int? id;
  final int porcinoId;
  final String tipo; // 'vacunacion' | 'tratamiento' | 'desparasitacion'
  final String medicamento;
  final String loteBiologico; // Obligatorio según trazabilidad ICA
  final double dosisMl;
  final String viaAplicacion; // 'Intramuscular profunda', 'Subcutánea', 'Oral'
  final DateTime fecha;
  final int diasRetiro;
  final DateTime fechaFinRetiro;
  final String? observaciones;

  const HealthEventEntity({
    this.id,
    required this.porcinoId,
    required this.tipo,
    required this.medicamento,
    required this.loteBiologico,
    required this.dosisMl,
    required this.viaAplicacion,
    required this.fecha,
    required this.diasRetiro,
    required this.fechaFinRetiro,
    this.observaciones,
  });

  bool get tieneRetiroActivo => DateTime.now().isBefore(fechaFinRetiro);

  @override
  List<Object?> get props => [
        id,
        porcinoId,
        tipo,
        medicamento,
        loteBiologico,
        dosisMl,
        viaAplicacion,
        fecha,
        diasRetiro,
        fechaFinRetiro,
        observaciones,
      ];
}
