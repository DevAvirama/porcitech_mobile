import 'package:equatable/equatable.dart';

class HealthEventEntity extends Equatable {
  final int? id;
  final String? uuid;
  final int porcinoId;
  final String? animalUuid;
  final String? animalArete;
  final String? corralCodigo;
  final String tipo; // 'vacuna' | 'tratamiento' | 'desparasitacion'
  final String medicamento;
  final String loteBiologico; // Obligatorio según trazabilidad ICA
  final double dosisMl;
  final String unidadDosis;
  final String viaAplicacion; // 'Intramuscular', 'Subcutánea', 'Oral', 'Tópica'
  final DateTime fecha;
  final int diasRetiro;
  final DateTime fechaFinRetiro;
  final String? diagnostico;
  final String? observaciones;
  final String? veterinarioNombre;

  const HealthEventEntity({
    this.id,
    this.uuid,
    required this.porcinoId,
    this.animalUuid,
    this.animalArete,
    this.corralCodigo,
    required this.tipo,
    required this.medicamento,
    required this.loteBiologico,
    required this.dosisMl,
    this.unidadDosis = 'ml',
    required this.viaAplicacion,
    required this.fecha,
    required this.diasRetiro,
    required this.fechaFinRetiro,
    this.diagnostico,
    this.observaciones,
    this.veterinarioNombre,
  });

  bool get tieneRetiroActivo => DateTime.now().isBefore(fechaFinRetiro) && diasRetiro > 0;

  @override
  List<Object?> get props => [
        id,
        uuid,
        porcinoId,
        animalUuid,
        animalArete,
        corralCodigo,
        tipo,
        medicamento,
        loteBiologico,
        dosisMl,
        unidadDosis,
        viaAplicacion,
        fecha,
        diasRetiro,
        fechaFinRetiro,
        diagnostico,
        observaciones,
        veterinarioNombre,
      ];
}

class WithdrawalAlertItem extends Equatable {
  final String animalUuid;
  final String animalArete;
  final String? corralCodigo;
  final String productoNombre;
  final DateTime fechaTratamiento;
  final int tiempoRetiroDias;
  final DateTime fechaFinRetiro;
  final int diasRestantes;

  const WithdrawalAlertItem({
    required this.animalUuid,
    required this.animalArete,
    this.corralCodigo,
    required this.productoNombre,
    required this.fechaTratamiento,
    required this.tiempoRetiroDias,
    required this.fechaFinRetiro,
    required this.diasRestantes,
  });

  @override
  List<Object?> get props => [
        animalUuid,
        animalArete,
        corralCodigo,
        productoNombre,
        fechaTratamiento,
        tiempoRetiroDias,
        fechaFinRetiro,
        diasRestantes,
      ];
}

class BiosecurityProtocolItem extends Equatable {
  final String id;
  final String codigo;
  final String tipoProtocolo; // 'estructural' | 'operacional'
  final String tarea;
  final String descripcion;
  final String frecuencia;
  final bool cumplidoHoy;
  final String? observacionesHoy;

  const BiosecurityProtocolItem({
    required this.id,
    required this.codigo,
    required this.tipoProtocolo,
    required this.tarea,
    required this.descripcion,
    required this.frecuencia,
    this.cumplidoHoy = false,
    this.observacionesHoy,
  });

  BiosecurityProtocolItem copyWith({
    bool? cumplidoHoy,
    String? observacionesHoy,
  }) {
    return BiosecurityProtocolItem(
      id: id,
      codigo: codigo,
      tipoProtocolo: tipoProtocolo,
      tarea: tarea,
      descripcion: descripcion,
      frecuencia: frecuencia,
      cumplidoHoy: cumplidoHoy ?? this.cumplidoHoy,
      observacionesHoy: observacionesHoy ?? this.observacionesHoy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        codigo,
        tipoProtocolo,
        tarea,
        descripcion,
        frecuencia,
        cumplidoHoy,
        observacionesHoy,
      ];
}
