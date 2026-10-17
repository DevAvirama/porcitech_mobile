import 'package:equatable/equatable.dart';

class PesoHistoricoItem extends Equatable {
  final DateTime fecha;
  final double pesoKg;
  final String metodo; // 'manual' | 'ia'

  const PesoHistoricoItem({
    required this.fecha,
    required this.pesoKg,
    this.metodo = 'manual',
  });

  @override
  List<Object?> get props => [fecha, pesoKg, metodo];
}

/// Entidad inmutable que modela al porcino con trazabilidad zootécnica completa.
/// Los aretes de identificación visual (código) son amigables para el operario (ej. POR-4092),
/// nunca exponiendo UUIDs crudos.
class PorcinoEntity extends Equatable {
  final int id;
  final String? uuid; // UUID original en PostgreSQL / FastAPI
  final String codigo; // Arete de campo (ej: POR-4092, H-104)
  final String raza; // Landrace, Large White, Pietrain, Duroc
  final String sexo; // 'Hembra' | 'Macho' | 'Macho Castrado'
  final DateTime fechaNacimiento;
  final int loteId;
  final String loteNombre;
  final double pesoActual;
  final String estadoSanitario; // 'Sano', 'Enfermo', 'En Tratamiento', 'Retiro Farmacológico'
  final String fase; // 'Ceba', 'Gestación', 'Maternidad', 'Precebo'
  final double gdpActualGramoDia; // GDP calculada
  final int diasEnFase;
  final String? medicacionActiva;
  final int diasRetiroRestantes;
  final DateTime? fechaFinRetiro;
  final List<PesoHistoricoItem> curvaCrecimiento;

  const PorcinoEntity({
    required this.id,
    this.uuid,
    required this.codigo,
    required this.raza,
    required this.sexo,
    required this.fechaNacimiento,
    required this.loteId,
    required this.loteNombre,
    required this.pesoActual,
    required this.estadoSanitario,
    required this.fase,
    required this.gdpActualGramoDia,
    required this.diasEnFase,
    this.medicacionActiva,
    this.diasRetiroRestantes = 0,
    this.fechaFinRetiro,
    this.curvaCrecimiento = const [],
  });

  int get edadEnDias => DateTime.now().difference(fechaNacimiento).inDays;
  bool get esHembraReproductora => sexo == 'Hembra' && (fase == 'Gestación' || fase == 'Maternidad' || fase == 'Hembra Vacía');
  bool get tieneRetiroFarmacologicoActivo => diasRetiroRestantes > 0;

  @override
  List<Object?> get props => [
        id,
        uuid,
        codigo,
        raza,
        sexo,
        fechaNacimiento,
        loteId,
        loteNombre,
        pesoActual,
        estadoSanitario,
        fase,
        gdpActualGramoDia,
        diasEnFase,
        medicacionActiva,
        diasRetiroRestantes,
        fechaFinRetiro,
        curvaCrecimiento,
      ];
}

/// Entidad inmutable que representa un Lote de animales en galpón.
class LoteEntity extends Equatable {
  final int id;
  final String? uuid;
  final String codigo;
  final String nombre;
  final String fase;
  final int cantidadPorcinos;
  final double pesoPromedio;
  final String galpon;

  const LoteEntity({
    required this.id,
    this.uuid,
    required this.codigo,
    required this.nombre,
    required this.fase,
    required this.cantidadPorcinos,
    required this.pesoPromedio,
    required this.galpon,
  });

  @override
  List<Object?> get props => [
        id,
        uuid,
        codigo,
        nombre,
        fase,
        cantidadPorcinos,
        pesoPromedio,
        galpon,
      ];
}
