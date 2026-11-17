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
      return Right(_getCachedPorcinos(query: query, filter: filter));
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
      return Right(_getCachedPorcinos(query: query, filter: filter));
    } on AppException {
      return Right(_getCachedPorcinos(query: query, filter: filter));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PorcinoEntity>> getPorcinoById(int id, {String? uuid}) async {
    if (cacheService.isOfflineModeEnabled()) {
      final list = _getCachedPorcinos();
      final found = list.cast<PorcinoEntity?>().firstWhere(
            (p) => p?.id == id || (uuid != null && p?.uuid == uuid),
            orElse: () => null,
          );
      if (found != null) return Right(found);
      return const Left(NotFoundFailure('Porcino no localizado en almacenamiento local.'));
    }

    try {
      final item = await remoteDataSource.getPorcinoById(id, uuid: uuid);
      return Right(item);
    } on AppException {
      final list = _getCachedPorcinos();
      final found = list.cast<PorcinoEntity?>().firstWhere(
            (p) => p?.id == id || (uuid != null && p?.uuid == uuid),
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
      final list = _getCachedPorcinos();
      final found = list.cast<PorcinoEntity?>().firstWhere(
            (p) =>
                p?.codigo.toUpperCase() == cleanCode ||
                p?.codigoQr?.toUpperCase() == cleanCode ||
                p?.codigo.toUpperCase().contains(cleanCode) == true,
            orElse: () => null,
          );
      if (found != null) return Right(found);
      return Left(NotFoundFailure('No se encontró porcino con arete/código $codigo'));
    }

    try {
      final item = await remoteDataSource.getPorcinoByQr(cleanCode);
      return Right(item);
    } on AppException {
      final list = _getCachedPorcinos();
      final found = list.cast<PorcinoEntity?>().firstWhere(
            (p) =>
                p?.codigo.toUpperCase() == cleanCode ||
                p?.codigoQr?.toUpperCase() == cleanCode ||
                p?.codigo.toUpperCase().contains(cleanCode) == true,
            orElse: () => null,
          );
      if (found != null) return Right(found);
      return Left(NotFoundFailure('No se encontró porcino con arete $codigo'));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PesoHistoricoItem>>> getHistorialPesajes(
    int id, {
    String? uuid,
  }) async {
    if (cacheService.isOfflineModeEnabled()) {
      return const Right([]);
    }
    try {
      final items = await remoteDataSource.getHistorialPesajes(id, uuid: uuid);
      return Right(items);
    } catch (e) {
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, PorcinoEntity>> createPorcino({
    required String codigo,
    String? nombreAlias,
    required String raza,
    required String sexo,
    required DateTime fechaNacimiento,
    required int loteId,
    String? corralUuid,
    String estado = 'levante',
    double pesoInicialKg = 0.0,
  }) async {
    final resolvedCorralUuid = corralUuid ?? LoteModel.resolveUuid(loteId);
    final lotes = _getCachedLotes();
    final matchedLote = lotes.cast<LoteEntity?>().firstWhere(
          (l) => l?.id == loteId || (resolvedCorralUuid != null && l?.uuid == resolvedCorralUuid),
          orElse: () => null,
        );

    final newModel = PorcinoModel(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      corralUuid: resolvedCorralUuid,
      codigo: codigo.trim(),
      codigoQr: 'QR-${codigo.trim()}',
      nombreAlias: nombreAlias,
      raza: raza,
      sexo: sexo,
      fechaNacimiento: fechaNacimiento,
      loteId: loteId,
      loteNombre: matchedLote?.codigo ?? 'Corral $loteId',
      pesoActual: pesoInicialKg > 0 ? pesoInicialKg : 0.0,
      estadoSanitario: 'Sano',
      fase: estado,
      gdpActualGramoDia: 0.0,
      diasEnFase: 1,
    );

    final normalizedEstado = () {
      final f = estado.trim().toLowerCase();
      if (f.contains('gesta')) return 'gestacion';
      if (f.contains('mater') || f.contains('lacta')) return 'lactante';
      if (f.contains('prece') || f.contains('deste')) return 'precebo';
      if (f.contains('levan')) return 'levante';
      if (f.contains('cuaren')) return 'cuarentena';
      if (f.contains('enfer')) return 'enfermo';
      if (f.contains('reprod') || f.contains('activ')) return 'activo';
      return 'engorde';
    }();

    final offlineAnimalPayload = <String, dynamic>{
      '_local_animal_id': newModel.id,
      'codigo_arete': codigo.trim(),
      'codigo_qr': 'QR-${codigo.trim()}',
      if (nombreAlias != null && nombreAlias.trim().isNotEmpty)
        'nombre_alias': nombreAlias.trim(),
      'raza': raza,
      'sexo': sexo.toLowerCase().contains('macho') ? 'macho' : 'hembra',
      'fecha_nacimiento': fechaNacimiento.toIso8601String().split('T').first,
      'estado': normalizedEstado,
      'corral_id': ?resolvedCorralUuid,
      if (resolvedCorralUuid == null) '_local_corral_id': loteId,
      'peso_actual_kg': pesoInicialKg,
    };

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: '/animales',
        method: 'POST',
        payload: offlineAnimalPayload,
        description: 'Registro de porcino arete $codigo',
      );
      _addPorcinoToCache(newModel);
      return Right(newModel);
    }

    try {
      final remote = await remoteDataSource.createPorcino(
        codigo: codigo,
        nombreAlias: nombreAlias,
        raza: raza,
        sexo: sexo,
        fechaNacimiento: fechaNacimiento,
        loteId: loteId,
        corralUuid: resolvedCorralUuid,
        estado: normalizedEstado,
        pesoInicialKg: pesoInicialKg,
      );
      _addPorcinoToCache(remote);
      return Right(remote);
    } on AppException catch (e) {
      if (e.statusCode != null && e.statusCode! >= 400 && e.statusCode! < 500) {
        return Left(ServerFailure(e.message, e.statusCode));
      }
      await cacheService.enqueueSyncItem(
        endpoint: '/animales',
        method: 'POST',
        payload: offlineAnimalPayload,
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
      return Right(_getCachedLotes());
    }

    try {
      final list = await remoteDataSource.getLotes();
      if (list.isNotEmpty) {
        final jsonList = list.map((e) => e.toJson()).toList();
        await cacheService.cacheJson(cacheService.keyCachedLotes, jsonList);
        return Right(list);
      }
      return Right(_getCachedLotes());
    } on AppException {
      return Right(_getCachedLotes());
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
    int capacidadMaxima = 25,
  }) async {
    final model = LoteModel(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      codigo: codigo,
      nombre: nombre,
      fase: fase,
      cantidadPorcinos: 0,
      capacidadMaxima: capacidadMaxima,
      pesoPromedio: 0.0,
      galpon: galpon,
    );

    final f = fase.toLowerCase();
    String faseBackend = 'ceba';
    if (f.contains('gesta')) {
      faseBackend = 'gestacion';
    } else if (f.contains('mater') || f.contains('lacta')) {
      faseBackend = 'maternidad';
    } else if (f.contains('deste') || f.contains('prece')) {
      faseBackend = 'precebo';
    } else if (f.contains('levan')) {
      faseBackend = 'levante';
    } else if (f.contains('cuaren')) {
      faseBackend = 'cuarentena';
    }

    final offlineLotePayload = <String, dynamic>{
      '_local_corral_id': model.id,
      'codigo': codigo.trim(),
      'descripcion': nombre.trim().isNotEmpty ? '${nombre.trim()} • $galpon' : galpon,
      'fase': faseBackend,
      'capacidad_maxima': capacidadMaxima,
      'activo': true,
    };

    if (cacheService.isOfflineModeEnabled()) {
      await cacheService.enqueueSyncItem(
        endpoint: '/corrales',
        method: 'POST',
        payload: offlineLotePayload,
        description: 'Creación de corral $codigo ($nombre)',
      );
      _addLoteToCache(model);
      return Right(model);
    }

    try {
      final remote = await remoteDataSource.createLote(
        codigo: codigo,
        nombre: nombre,
        fase: fase,
        galpon: galpon,
        capacidadMaxima: capacidadMaxima,
      );
      _addLoteToCache(remote);
      return Right(remote);
    } on AppException catch (e) {
      if (e.statusCode != null && e.statusCode! >= 400 && e.statusCode! < 500) {
        return Left(ServerFailure(e.message, e.statusCode));
      }
      await cacheService.enqueueSyncItem(
        endpoint: '/corrales',
        method: 'POST',
        payload: offlineLotePayload,
        description: 'Creación de corral $codigo ($nombre)',
      );
      _addLoteToCache(model);
      return Right(model);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  void _addLoteToCache(LoteModel model) {
    final cached = _getCachedLotes();
    cached.insert(0, model);
    final jsonList = cached.map((e) {
      if (e is LoteModel) return e.toJson();
      return (e as dynamic).toJson();
    }).toList();
    cacheService.cacheJson(cacheService.keyCachedLotes, jsonList);
  }

  void _addPorcinoToCache(PorcinoModel model) {
    final cached = _getCachedPorcinos();
    cached.insert(0, model);
    final jsonList = cached.map((e) {
      if (e is PorcinoModel) return e.toJson();
      return (e as dynamic).toJson();
    }).toList();
    cacheService.cacheJson(cacheService.keyCachedAnimals, jsonList);
  }

  List<PorcinoEntity> _getCachedPorcinos({String? query, String? filter}) {
    List<PorcinoModel> list = [];
    final cachedJson = cacheService.getCachedJson(cacheService.keyCachedAnimals);
    if (cachedJson != null && cachedJson is List) {
      list = cachedJson
          .whereType<Map<String, dynamic>>()
          .map(PorcinoModel.fromJson)
          .toList();
    }

    var filtered = list;
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = filtered
          .where((p) =>
              p.codigo.toLowerCase().contains(q) ||
              (p.nombreAlias?.toLowerCase().contains(q) ?? false) ||
              p.raza.toLowerCase().contains(q) ||
              p.loteNombre.toLowerCase().contains(q))
          .toList();
    }

    if (filter != null && filter != 'Todos') {
      if (filter == 'Enfermos') {
        filtered = filtered
            .where((p) =>
                p.estadoSanitario == 'Enfermo' ||
                p.estadoSanitario == 'En Tratamiento' ||
                p.estadoSanitario == 'Retiro Farmacológico')
            .toList();
      } else {
        filtered = filtered
            .where((p) => p.fase.toLowerCase() == filter.toLowerCase())
            .toList();
      }
    }

    return filtered;
  }

  List<LoteEntity> _getCachedLotes() {
    final cachedJson = cacheService.getCachedJson(cacheService.keyCachedLotes);
    if (cachedJson != null && cachedJson is List) {
      return cachedJson
          .whereType<Map<String, dynamic>>()
          .map<LoteEntity>(LoteModel.fromJson)
          .toList();
    }
    return <LoteEntity>[];
  }
}
