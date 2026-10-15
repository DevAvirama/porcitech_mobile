import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../domain/entities/porcino_entity.dart';
import '../../domain/repositories/animals_repository.dart';
import '../datasources/animals_remote_datasource.dart';
import '../models/lote_model.dart';
import '../models/porcino_model.dart';

class AnimalsRepositoryImpl implements AnimalsRepository {
  final AnimalsRemoteDataSource remoteDataSource;
  final LocalCacheService cacheService;

  AnimalsRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheService,
  });

  @override
  Future<Either<Failure, List<PorcinoEntity>>> getPorcinos({
    String? query,
    String? filter,
  }) async {
    if (cacheService.isOfflineModeEnabled()) {
      return Right(_getCachedOrSeedPorcinos(query: query, filter: filter));
    }

    try {
      final remoteList = await remoteDataSource.getPorcinos(
        query: query,
        filter: filter,
      );
      if (remoteList.isNotEmpty) {
        final jsonList = remoteList.map((e) => e.toJson()).toList();
        await cacheService.cacheJson(cacheService.keyCachedAnimals, jsonList);
        return Right(remoteList);
      }
      return Right(_getCachedOrSeedPorcinos(query: query, filter: filter));
    } on AppException {
      return Right(_getCachedOrSeedPorcinos(query: query, filter: filter));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PorcinoEntity>> getPorcinoById(int id) async {
    if (cacheService.isOfflineModeEnabled()) {
      final list = _getCachedOrSeedPorcinos();
      final found = list.cast<PorcinoEntity?>().firstWhere(
            (p) => p?.id == id,
            orElse: () => null,
          );
      if (found != null) return Right(found);
      return const Left(NotFoundFailure('Porcino no localizado en almacenamiento local.'));
    }

    try {
      final item = await remoteDataSource.getPorcinoById(id);
      return Right(item);
    } on AppException {
      final list = _getCachedOrSeedPorcinos();
      final found = list.cast<PorcinoEntity?>().firstWhere(
            (p) => p?.id == id,
            orElse: () => null,
          );
      if (found != null) return Right(found);
      return const Left(NotFoundFailure());
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PorcinoEntity>> getPorcinoByQr(String codigo) async {
    final cleanCode = codigo.trim().toUpperCase();

    if (cacheService.isOfflineModeEnabled()) {
      final list = _getCachedOrSeedPorcinos();
      final found = list.cast<PorcinoEntity?>().firstWhere(
            (p) => p?.codigo.toUpperCase() == cleanCode || p?.codigo.toUpperCase().contains(cleanCode) == true,
            orElse: () => null,
          );
      if (found != null) return Right(found);
      return Left(NotFoundFailure('No se encontró porcino con arete/código $codigo'));
    }

    try {
      final item = await remoteDataSource.getPorcinoByQr(cleanCode);
      return Right(item);
    } on AppException {
      final list = _getCachedOrSeedPorcinos();
      final found = list.cast<PorcinoEntity?>().firstWhere(
            (p) => p?.codigo.toUpperCase() == cleanCode || p?.codigo.toUpperCase().contains(cleanCode) == true,
            orElse: () => null,
          );
      if (found != null) return Right(found);
      return Left(NotFoundFailure('No se encontró porcino con arete $codigo'));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PorcinoEntity>> createPorcino({
    required String codigo,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required int loteId,
  }) async {
    final newModel = PorcinoModel(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      codigo: codigo,
      raza: raza,
      sexo: sexo,
      fechaNacimiento: fechaNacimiento,
      loteId: loteId,
      loteNombre: 'Lote $loteId',
      pesoActual: 18.5,
      estadoSanitario: 'Sano',
      fase: 'Precebo',
      gdpActualGramoDia: 520.0,
      diasEnFase: 1,
    );

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: '/api/porcinos/',
        method: 'POST',
        payload: {
          'codigo': codigo,
          'raza': raza,
          'sexo': sexo,
          'fecha_nacimiento': fechaNacimiento.toIso8601String().split('T').first,
          'lote': loteId,
        },
        description: 'Registro de porcino arete $codigo',
      );
      _addPorcinoToCache(newModel);
      return Right(newModel);
    }

    try {
      final remote = await remoteDataSource.createPorcino(
        codigo: codigo,
        raza: raza,
        sexo: sexo,
        fechaNacimiento: fechaNacimiento,
        loteId: loteId,
      );
      _addPorcinoToCache(remote);
      return Right(remote);
    } on AppException {
      await cacheService.enqueueSyncItem(
        endpoint: '/api/porcinos/',
        method: 'POST',
        payload: {
          'codigo': codigo,
          'raza': raza,
          'sexo': sexo,
          'fecha_nacimiento': fechaNacimiento.toIso8601String().split('T').first,
          'lote': loteId,
        },
        description: 'Registro de porcino arete $codigo',
      );
      _addPorcinoToCache(newModel);
      return Right(newModel);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LoteEntity>>> getLotes() async {
    if (cacheService.isOfflineModeEnabled()) {
      return Right(_getCachedOrSeedLotes());
    }

    try {
      final list = await remoteDataSource.getLotes();
      if (list.isNotEmpty) {
        final jsonList = list.map((e) => e.toJson()).toList();
        await cacheService.cacheJson(cacheService.keyCachedLotes, jsonList);
        return Right(list);
      }
      return Right(_getCachedOrSeedLotes());
    } on AppException {
      return Right(_getCachedOrSeedLotes());
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LoteEntity>> createLote({
    required String codigo,
    required String nombre,
    required String fase,
    required String galpon,
  }) async {
    final model = LoteModel(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      codigo: codigo,
      nombre: nombre,
      fase: fase,
      cantidadPorcinos: 0,
      pesoPromedio: 0.0,
      galpon: galpon,
    );

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: '/api/lotes/',
        method: 'POST',
        payload: {
          'codigo': codigo,
          'nombre': nombre,
          'fase': fase,
          'galpon': galpon,
        },
        description: 'Creación de lote $codigo ($nombre)',
      );
      return Right(model);
    }

    try {
      final remote = await remoteDataSource.createLote(
        codigo: codigo,
        nombre: nombre,
        fase: fase,
        galpon: galpon,
      );
      return Right(remote);
    } on AppException {
      await cacheService.enqueueSyncItem(
        endpoint: '/api/lotes/',
        method: 'POST',
        payload: {
          'codigo': codigo,
          'nombre': nombre,
          'fase': fase,
          'galpon': galpon,
        },
        description: 'Creación de lote $codigo ($nombre)',
      );
      return Right(model);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  void _addPorcinoToCache(PorcinoModel model) {
    final cached = _getCachedOrSeedPorcinos();
    cached.insert(0, model);
    final jsonList = cached.map((e) {
      if (e is PorcinoModel) return e.toJson();
      return (e as dynamic).toJson();
    }).toList();
    cacheService.cacheJson(cacheService.keyCachedAnimals, jsonList);
  }

  List<PorcinoEntity> _getCachedOrSeedPorcinos({String? query, String? filter}) {
    List<PorcinoModel> list = [];
    final cachedJson = cacheService.getCachedJson(cacheService.keyCachedAnimals);
    if (cachedJson != null && cachedJson is List) {
      list = cachedJson.map((e) => PorcinoModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    if (list.isEmpty) {
      // Semilla zootécnica de alta fidelidad
      list = [
        PorcinoModel(
          id: 4092,
          codigo: 'POR-4092',
          raza: 'Landrace x Pietrain',
          sexo: 'Macho Castrado',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 145)),
          loteId: 3,
          loteNombre: 'Lote Ceba 03',
          pesoActual: 82.5,
          estadoSanitario: 'Sano',
          fase: 'Ceba',
          gdpActualGramoDia: 820.0,
          diasEnFase: 65,
        ),
        PorcinoModel(
          id: 104,
          codigo: 'CERDA-H-104',
          raza: 'Landrace Puro',
          sexo: 'Hembra',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 480)),
          loteId: 1,
          loteNombre: 'Lote Reproductoras A',
          pesoActual: 215.0,
          estadoSanitario: 'Sana',
          fase: 'Gestación',
          gdpActualGramoDia: 380.0,
          diasEnFase: 110,
        ),
        PorcinoModel(
          id: 2015,
          codigo: 'POR-2015',
          raza: 'Duroc',
          sexo: 'Macho',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 90)),
          loteId: 2,
          loteNombre: 'Lote Levante Norte',
          pesoActual: 48.0,
          estadoSanitario: 'Retiro Farmacológico',
          fase: 'Levante',
          gdpActualGramoDia: 740.0,
          diasEnFase: 35,
          medicacionActiva: 'Oxitetraciclina L.A.',
          diasRetiroRestantes: 12,
          fechaFinRetiro: DateTime.now().add(const Duration(days: 12)),
        ),
        PorcinoModel(
          id: 503,
          codigo: 'POR-503',
          raza: 'Large White',
          sexo: 'Hembra',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 120)),
          loteId: 3,
          loteNombre: 'Lote Ceba 03',
          pesoActual: 76.0,
          estadoSanitario: 'En Tratamiento',
          fase: 'Ceba',
          gdpActualGramoDia: 680.0,
          diasEnFase: 50,
          medicacionActiva: 'Amoxicilina Trihidrato',
          diasRetiroRestantes: 5,
          fechaFinRetiro: DateTime.now().add(const Duration(days: 5)),
        ),
      ];
    }

    var filtered = list;
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = filtered.where((p) =>
          p.codigo.toLowerCase().contains(q) ||
          p.raza.toLowerCase().contains(q) ||
          p.loteNombre.toLowerCase().contains(q)).toList();
    }

    if (filter != null && filter != 'Todos') {
      if (filter == 'Enfermos') {
        filtered = filtered.where((p) =>
            p.estadoSanitario == 'Enfermo' ||
            p.estadoSanitario == 'En Tratamiento' ||
            p.estadoSanitario == 'Retiro Farmacológico').toList();
      } else {
        filtered = filtered.where((p) => p.fase.toLowerCase() == filter.toLowerCase()).toList();
      }
    }

    return filtered;
  }

  List<LoteEntity> _getCachedOrSeedLotes() {
    return const [
      LoteModel(
        id: 1,
        codigo: 'LOT-REP-01',
        nombre: 'Lote Reproductoras A',
        fase: 'Gestación',
        cantidadPorcinos: 32,
        pesoPromedio: 210.5,
        galpon: 'Galpón 1 - Maternidad & Gestación',
      ),
      LoteModel(
        id: 2,
        codigo: 'LOT-LEV-02',
        nombre: 'Lote Levante Norte',
        fase: 'Levante',
        cantidadPorcinos: 120,
        pesoPromedio: 47.8,
        galpon: 'Galpón 3 - Levante',
      ),
      LoteModel(
        id: 3,
        codigo: 'LOT-CEB-03',
        nombre: 'Lote Ceba 03',
        fase: 'Ceba',
        cantidadPorcinos: 180,
        pesoPromedio: 81.4,
        galpon: 'Galpón 4 - Ceba Tecnificada',
      ),
    ];
  }
}
